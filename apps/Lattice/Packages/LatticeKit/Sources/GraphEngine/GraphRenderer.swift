import Foundation
import Metal
import MetalKit
import QuartzCore
import simd

/// Visual configuration for the graph, kept separate from the physics so the two can be
/// tuned independently.
public struct GraphStyle: Sendable, Equatable {
    public var background: SIMD4<Float>
    public var edgeColor: SIMD4<Float>
    public var selectionColor: SIMD4<Float>
    public var edgeWidth: Float
    public var nodeScale: Float
    /// How far unrelated nodes fade when a neighbourhood is highlighted, 0...1.
    public var dimAmount: Float

    public static let dark = GraphStyle(
        background: SIMD4(0.055, 0.055, 0.070, 1),
        edgeColor: SIMD4(0.60, 0.66, 0.82, 0.34),
        selectionColor: SIMD4(1.00, 0.85, 0.35, 1),
        edgeWidth: 1.2,
        nodeScale: 1.0,
        dimAmount: 0.72
    )

    public static let light = GraphStyle(
        background: SIMD4(0.98, 0.98, 0.97, 1),
        edgeColor: SIMD4(0.20, 0.26, 0.38, 0.28),
        selectionColor: SIMD4(0.10, 0.42, 0.95, 1),
        edgeWidth: 1.2,
        nodeScale: 1.0,
        dimAmount: 0.68
    )

    public init(
        background: SIMD4<Float>,
        edgeColor: SIMD4<Float>,
        selectionColor: SIMD4<Float>,
        edgeWidth: Float,
        nodeScale: Float,
        dimAmount: Float
    ) {
        self.background = background
        self.edgeColor = edgeColor
        self.selectionColor = selectionColor
        self.edgeWidth = edgeWidth
        self.nodeScale = nodeScale
        self.dimAmount = dimAmount
    }
}

/// Drives the simulation and draws the graph into an `MTKView`.
///
/// One command buffer per frame carries both the compute step and the render pass, so the
/// layout never lags a frame behind what is on screen.
@MainActor
public final class GraphRenderer: NSObject {
    public let simulation: GraphSimulation
    public var style: GraphStyle = .dark
    public var camera = GraphCamera()

    /// Node under the pointer, dimming everything outside its neighbourhood.
    public var highlightedNode: Int?
    /// Node the user has opened.
    public var selectedNode: Int?

    /// Set when the layout is settled and no interaction is in flight; the view stops
    /// asking for frames entirely, which is what keeps an idle graph off the battery.
    public private(set) var isPaused = false

    /// Fires once, after the first settled layout, so the caller can frame the graph.
    ///
    /// Explicitly `@MainActor` so the closure body may touch the renderer directly;
    /// a bare `() -> Void` would be inferred nonisolated and could not.
    public var onFirstSettle: (@MainActor () -> Void)?

    /// The view being drawn into.
    ///
    /// Held here so anything that restarts the layout — a gesture, a parameter change, a
    /// freshly loaded graph — can also lift the pause, without every caller having to
    /// thread the view through. Weak because the view owns the renderer as its delegate.
    public weak var attachedView: MTKView?

    private let commandQueue: MTLCommandQueue
    private let edgePipeline: MTLRenderPipelineState
    private let nodePipeline: MTLRenderPipelineState
    private var viewportSize = SIMD2<Float>(1, 1)
    private var hasSettledOnce = false
    private var startTime = CACurrentMediaTime()

    public init(simulation: GraphSimulation, pixelFormat: MTLPixelFormat, sampleCount: Int) throws {
        self.simulation = simulation
        let device = simulation.device

        guard let queue = device.makeCommandQueue() else {
            throw GraphEngineError.metalUnavailable
        }
        commandQueue = queue

        let library: MTLLibrary
        do {
            library = try device.makeDefaultLibrary(bundle: .module)
        } catch {
            throw GraphEngineError.shaderLibraryMissing
        }

        func makePipeline(
            vertex: String,
            fragment: String
        ) throws -> MTLRenderPipelineState {
            guard let vertexFunction = library.makeFunction(name: vertex) else {
                throw GraphEngineError.functionMissing(vertex)
            }
            guard let fragmentFunction = library.makeFunction(name: fragment) else {
                throw GraphEngineError.functionMissing(fragment)
            }
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertexFunction
            descriptor.fragmentFunction = fragmentFunction
            descriptor.rasterSampleCount = sampleCount

            let attachment = descriptor.colorAttachments[0]
            attachment.pixelFormat = pixelFormat
            // Straight (non-premultiplied) alpha, matching what the shaders emit.
            attachment.isBlendingEnabled = true
            attachment.rgbBlendOperation = .add
            attachment.alphaBlendOperation = .add
            attachment.sourceRGBBlendFactor = .sourceAlpha
            attachment.sourceAlphaBlendFactor = .sourceAlpha
            attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
            attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha

            return try device.makeRenderPipelineState(descriptor: descriptor)
        }

        edgePipeline = try makePipeline(
            vertex: "graph_edge_vertex",
            fragment: "graph_edge_fragment"
        )
        nodePipeline = try makePipeline(
            vertex: "graph_node_vertex",
            fragment: "graph_node_fragment"
        )
        super.init()
    }

    // MARK: - Frame

    public func render(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor
        else { return }

        descriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: Double(style.background.x),
            green: Double(style.background.y),
            blue: Double(style.background.z),
            alpha: Double(style.background.w)
        )

        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        // Fold in the reduction the previous frame wrote. Doing this first keeps the CPU
        // off the GPU's critical path — nothing here waits on work that is still in
        // flight — and means `isSettled` below reflects the latest completed step.
        simulation.consumeStats()

        // Step the layout unless it has come to rest; a settled graph still draws, so
        // pan and zoom stay responsive without burning GPU time on physics.
        if !simulation.isSettled {
            simulation.encodeStep(into: commandBuffer)
        } else {
            simulation.cachePositions()
            if !hasSettledOnce {
                hasSettledOnce = true
                // Runs before the pass is encoded so the camera it sets is used by this
                // frame; otherwise the fit would land after the view has already paused.
                onFirstSettle?()
            }
        }

        encodeRenderPass(descriptor: descriptor, commandBuffer: commandBuffer)

        commandBuffer.present(drawable)
        commandBuffer.commit()

        updatePauseState()
    }

    private func encodeRenderPass(
        descriptor: MTLRenderPassDescriptor,
        commandBuffer: MTLCommandBuffer
    ) {
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        // An empty graph still needs the pass to run so the background gets cleared.
        guard let positions = simulation.renderPositions,
              let meta = simulation.renderMeta
        else {
            encoder.endEncoding()
            return
        }

        var uniforms = RenderUniforms(
            viewportSize: viewportSize,
            cameraCenter: camera.center,
            cameraScale: camera.scale,
            nodeScale: style.nodeScale,
            edgeWidth: style.edgeWidth,
            time: Float(CACurrentMediaTime() - startTime),
            edgeColor: style.edgeColor,
            selectionColor: style.selectionColor,
            highlightIndex: highlightedNode.map(UInt32.init) ?? GraphShaderTypes.noIndex,
            selectedIndex: selectedNode.map(UInt32.init) ?? GraphShaderTypes.noIndex,
            dimAmount: style.dimAmount
        )
        let uniformsLength = MemoryLayout<RenderUniforms>.stride

        // Edges first so nodes sit on top of them.
        if simulation.snapshot.edgeCount > 0,
           let edges = simulation.renderEdges,
           let weights = simulation.renderEdgeWeights {
            encoder.setRenderPipelineState(edgePipeline)
            encoder.setVertexBuffer(positions, offset: 0, index: 0)
            encoder.setVertexBuffer(edges, offset: 0, index: 1)
            encoder.setVertexBuffer(weights, offset: 0, index: 2)
            encoder.setVertexBytes(&uniforms, length: uniformsLength, index: 3)
            encoder.drawPrimitives(
                type: .triangle,
                vertexStart: 0,
                vertexCount: 6,
                instanceCount: simulation.snapshot.edgeCount
            )
        }

        if simulation.snapshot.nodeCount > 0 {
            encoder.setRenderPipelineState(nodePipeline)
            encoder.setVertexBuffer(positions, offset: 0, index: 0)
            encoder.setVertexBuffer(meta, offset: 0, index: 1)
            encoder.setVertexBytes(&uniforms, length: uniformsLength, index: 2)
            encoder.drawPrimitives(
                type: .triangle,
                vertexStart: 0,
                vertexCount: 6,
                instanceCount: simulation.snapshot.nodeCount
            )
        }

        encoder.endEncoding()
    }

    // MARK: - Pausing

    /// Stops requesting frames once the layout is at rest.
    ///
    /// A force-directed graph that keeps simulating after it has converged is a battery
    /// fire, and the difference is invisible: nothing on screen is moving.
    private func updatePauseState() {
        let shouldPause = simulation.isSettled
        guard shouldPause != isPaused, let view = attachedView else { return }
        isPaused = shouldPause
        view.isPaused = shouldPause
        view.enableSetNeedsDisplay = shouldPause
    }

    /// Reheats the layout and brings the view back to continuous drawing.
    ///
    /// Both halves matter: reheating a simulation whose view is still paused looks like
    /// nothing happened at all.
    public func resume() {
        simulation.reheat()
        isPaused = false
        attachedView?.isPaused = false
        attachedView?.enableSetNeedsDisplay = false
    }

    /// Redraws once without restarting the simulation — for pan, zoom, and hover, which
    /// change what is on screen but not where anything is.
    public func setNeedsRedraw() {
        guard let view = attachedView, view.isPaused else { return }
        view.draw()
    }

    public func updateViewport(_ size: CGSize) {
        viewportSize = SIMD2(Float(max(size.width, 1)), Float(max(size.height, 1)))
    }

    /// Re-arms the one-shot auto-fit, so a newly loaded graph frames itself once it
    /// settles rather than inheriting the previous graph's camera.
    public func resetAutoFit() {
        hasSettledOnce = false
    }

    /// Frames the whole graph in the current viewport.
    public func fitToContent() {
        camera.fit(bounds: simulation.bounds, viewportSize: viewportSize)
    }

    public var currentViewportSize: SIMD2<Float> { viewportSize }
}

// MARK: - MTKViewDelegate

extension GraphRenderer: MTKViewDelegate {
    /// `MTKView` always calls its delegate on the main thread, but the protocol is not
    /// annotated to say so, hence the explicit assumption rather than a hop.
    public nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        MainActor.assumeIsolated {
            updateViewport(size)
        }
    }

    public nonisolated func draw(in view: MTKView) {
        MainActor.assumeIsolated {
            render(in: view)
        }
    }
}
