import Foundation
import Metal
import VaultCore
import simd

/// Errors raised while standing up the Metal pipeline.
public enum GraphEngineError: Error, LocalizedError {
    case metalUnavailable
    case shaderLibraryMissing
    case functionMissing(String)

    public var errorDescription: String? {
        switch self {
        case .metalUnavailable:
            return "This device has no Metal GPU available."
        case .shaderLibraryMissing:
            return "The GraphEngine Metal library could not be loaded from the bundle."
        case .functionMissing(let name):
            return "The Metal function '\(name)' is missing from the shader library."
        }
    }
}

/// GPU force-directed layout over a ``GraphSnapshot``.
///
/// Owns every GPU buffer for the graph and encodes one layout step at a time. Rendering
/// lives in ``GraphRenderer``; this type knows nothing about how the result is drawn,
/// which keeps the physics testable against a headless device.
///
/// Confined to the main actor because `MTKView` drives it from its draw callback and the
/// gesture handlers mutate it directly. All GPU work is still asynchronous — the actor
/// only guards the CPU-side bookkeeping.
@MainActor
public final class GraphSimulation {
    public private(set) var snapshot: GraphSnapshot = .empty
    public var parameters: GraphLayoutParameters = .default

    /// Kinetic energy per node from the most recent completed reduction.
    public private(set) var averageEnergy: Float = .greatestFiniteMagnitude
    /// World-space bounds from the most recent completed reduction.
    public private(set) var bounds: (min: SIMD2<Float>, max: SIMD2<Float>) = (.zero, .zero)
    /// True once the layout has stopped moving enough to be worth simulating.
    ///
    /// The forced-step floor matters: ``consumeStats()`` reads the reduction from a step
    /// that has already finished, so immediately after a reheat the newest numbers still
    /// describe the settled graph. Without a floor, every reheat would be undone by stale
    /// statistics one frame later and nothing would ever visibly move.
    public var isSettled: Bool {
        forcedSteps <= 0 && averageEnergy < parameters.settleThreshold
    }

    /// Steps to run regardless of measured energy.
    private var forcedSteps = 0

    let device: MTLDevice
    private let repulsionPipeline: MTLComputePipelineState
    private let attractionPipeline: MTLComputePipelineState
    private let integratePipeline: MTLComputePipelineState
    private let reducePipeline: MTLComputePipelineState

    /// Threadgroup width for every kernel. A power of two because ``graph_reduce`` halves
    /// it, and at least 128 so the GPU has enough threads in flight to hide memory
    /// latency on Apple silicon.
    private static let threadgroupSize = 256

    private var positionsBuffer: MTLBuffer?
    private var velocitiesBuffer: MTLBuffer?
    private var forcesBuffer: MTLBuffer?
    private var metaBuffer: MTLBuffer?
    private var adjacencyOffsetsBuffer: MTLBuffer?
    private var adjacencyNeighborsBuffer: MTLBuffer?
    private var adjacencyWeightsBuffer: MTLBuffer?
    private var edgesBuffer: MTLBuffer?
    private var edgeWeightsBuffer: MTLBuffer?
    private var statsBuffer: MTLBuffer?
    private var statsGroupCount = 0

    /// Positions from the previous snapshot, so a re-index does not restart the layout.
    private var lastPositions: [NoteID: SIMD2<Float>] = [:]
    /// Annealing factor; starts hot after a change and cools toward 1.
    private var temperature: Float = 1

    /// Discrete GPUs need an explicit blit before the CPU can read a buffer. On Apple
    /// silicon the same allocation is visible to both, so hit-testing reads it directly.
    let hasUnifiedMemory: Bool

    public init(device: MTLDevice? = nil) throws {
        guard let device = device ?? MTLCreateSystemDefaultDevice() else {
            throw GraphEngineError.metalUnavailable
        }
        self.device = device
        self.hasUnifiedMemory = device.hasUnifiedMemory

        let library: MTLLibrary
        do {
            library = try device.makeDefaultLibrary(bundle: .module)
        } catch {
            throw GraphEngineError.shaderLibraryMissing
        }

        func pipeline(_ name: String) throws -> MTLComputePipelineState {
            guard let function = library.makeFunction(name: name) else {
                throw GraphEngineError.functionMissing(name)
            }
            return try device.makeComputePipelineState(function: function)
        }

        repulsionPipeline = try pipeline("graph_repulsion")
        attractionPipeline = try pipeline("graph_attraction")
        integratePipeline = try pipeline("graph_integrate")
        reducePipeline = try pipeline("graph_reduce")

        GraphShaderTypes.validateLayout()
    }

    // MARK: - Loading

    /// Replaces the graph, preserving the positions of nodes that survived.
    ///
    /// New nodes are seeded at the centroid of whichever neighbours already have a
    /// position, rather than at random. That is what keeps an incremental re-index from
    /// visibly detonating the layout every time a file is saved.
    public func load(_ snapshot: GraphSnapshot) {
        self.snapshot = snapshot
        let count = snapshot.nodeCount
        guard count > 0 else {
            positionsBuffer = nil
            averageEnergy = 0
            bounds = (.zero, .zero)
            return
        }

        var positions = [SIMD2<Float>](repeating: .zero, count: count)
        var placed = [Bool](repeating: false, count: count)

        for (index, node) in snapshot.nodes.enumerated() {
            if let previous = lastPositions[node.id] {
                positions[index] = previous
                placed[index] = true
            }
        }

        // Two passes so a new node can inherit from neighbours placed in the first.
        for _ in 0..<2 {
            for index in 0..<count where !placed[index] {
                var sum = SIMD2<Float>.zero
                var found: Float = 0
                for neighbor in snapshot.neighbors(of: index) where placed[Int(neighbor)] {
                    sum += positions[Int(neighbor)]
                    found += 1
                }
                if found > 0 {
                    positions[index] = sum / found + Self.jitter(seed: index, magnitude: 12)
                    placed[index] = true
                }
            }
        }

        // Anything still unplaced is genuinely new and unconnected: lay it on a spiral,
        // which distributes far more evenly than uniform random points.
        let radius = 18 * Float(count).squareRoot()
        for index in 0..<count where !placed[index] {
            let angle = Float(index) * 2.399963  // golden angle, in radians
            let distance = radius * (Float(index) / Float(max(count, 1))).squareRoot()
            positions[index] = SIMD2(cos(angle) * distance, sin(angle) * distance)
        }

        let meta = snapshot.nodes.map { node -> NodeMeta in
            // Radius and mass grow with the logarithm of degree so a hub reads as a hub
            // without a single node dominating the whole canvas.
            let degree = Float(node.degree)
            let emphasis = 1 + log2(1 + degree)
            var flags = NodeFlags()
            if node.group < 0 { flags.insert(.placeholder) }
            return NodeMeta(
                mass: emphasis,
                radius: 3.0 * emphasis,
                group: UInt32(max(node.group, 0)),
                flags: flags.rawValue
            )
        }

        let edges = snapshot.edges.map { SIMD2<UInt32>(UInt32($0.source), UInt32($0.target)) }
        let edgeWeights = snapshot.edges.map(\.weight)

        positionsBuffer = makeBuffer(positions)
        velocitiesBuffer = makeBuffer([SIMD2<Float>](repeating: .zero, count: count))
        forcesBuffer = makeBuffer([SIMD2<Float>](repeating: .zero, count: count))
        metaBuffer = makeBuffer(meta)
        adjacencyOffsetsBuffer = makeBuffer(snapshot.adjacencyOffsets)
        adjacencyNeighborsBuffer = makeBuffer(paddedIfEmpty(snapshot.adjacencyNeighbors))
        adjacencyWeightsBuffer = makeBuffer(paddedIfEmpty(snapshot.adjacencyWeights))
        edgesBuffer = makeBuffer(paddedIfEmpty(edges))
        edgeWeightsBuffer = makeBuffer(paddedIfEmpty(edgeWeights))

        statsGroupCount = (count + Self.threadgroupSize - 1) / Self.threadgroupSize
        statsBuffer = makeBuffer([GraphStats](repeating: GraphStats(), count: statsGroupCount))

        temperature = 1.6
        averageEnergy = .greatestFiniteMagnitude
        forcedSteps = Self.forcedStepsAfterDisturbance
        refreshBoundsFromPositions()
    }

    /// Deterministic offset so two nodes seeded from the same neighbours do not land on
    /// top of each other and stall at zero force.
    private static func jitter(seed: Int, magnitude: Float) -> SIMD2<Float> {
        // Knuth's multiplicative hash, wrapped and taken positive, gives a well-spread
        // angle without dragging in a random number generator.
        let hashed = UInt32(truncatingIfNeeded: seed &* 2_654_435_761)
        let angle = Float(hashed % 6283) / 1000
        return SIMD2(cos(angle), sin(angle)) * magnitude
    }

    // MARK: - Stepping

    /// Encodes one full layout step: repulsion, attraction, integration, reduction.
    ///
    /// Returns false when there is nothing to simulate, so the caller can skip the
    /// command buffer entirely rather than submitting empty work every frame.
    @discardableResult
    public func encodeStep(into commandBuffer: MTLCommandBuffer) -> Bool {
        let count = snapshot.nodeCount
        guard count > 0,
              let positions = positionsBuffer,
              let velocities = velocitiesBuffer,
              let forces = forcesBuffer,
              let meta = metaBuffer,
              let offsets = adjacencyOffsetsBuffer,
              let neighbors = adjacencyNeighborsBuffer,
              let weights = adjacencyWeightsBuffer,
              let stats = statsBuffer,
              let encoder = commandBuffer.makeComputeCommandEncoder()
        else { return false }

        // Cool toward 1 so the graph reorganises quickly after a change and then settles.
        temperature = max(1, temperature * 0.97)
        forcedSteps = max(0, forcedSteps - 1)

        let tuned = parameters.normalized(forNodeCount: count)
        var uniforms = LayoutUniforms(
            nodeCount: UInt32(count),
            deltaTime: tuned.timeStep,
            repulsion: tuned.repulsion,
            springStrength: tuned.springStrength,
            idealLength: tuned.idealLength,
            damping: tuned.damping,
            gravity: tuned.gravity,
            maxSpeed: tuned.maxSpeed,
            softening: tuned.softening,
            temperature: temperature
        )

        let threads = MTLSize(width: Self.threadgroupSize, height: 1, depth: 1)
        // Round the grid up to a whole number of threadgroups: the tiled repulsion kernel
        // needs every thread in a group present to cooperate on its barriers.
        let groups = MTLSize(
            width: (count + Self.threadgroupSize - 1) / Self.threadgroupSize,
            height: 1,
            depth: 1
        )

        for _ in 0..<max(1, parameters.stepsPerFrame) {
            encoder.setComputePipelineState(repulsionPipeline)
            encoder.setBuffer(positions, offset: 0, index: 0)
            encoder.setBuffer(meta, offset: 0, index: 1)
            encoder.setBuffer(forces, offset: 0, index: 2)
            encoder.setBytes(&uniforms, length: MemoryLayout<LayoutUniforms>.stride, index: 3)
            encoder.setThreadgroupMemoryLength(
                MemoryLayout<SIMD4<Float>>.stride * Self.threadgroupSize,
                index: 0
            )
            encoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)

            encoder.setComputePipelineState(attractionPipeline)
            encoder.setBuffer(positions, offset: 0, index: 0)
            encoder.setBuffer(forces, offset: 0, index: 1)
            encoder.setBuffer(offsets, offset: 0, index: 2)
            encoder.setBuffer(neighbors, offset: 0, index: 3)
            encoder.setBuffer(weights, offset: 0, index: 4)
            encoder.setBytes(&uniforms, length: MemoryLayout<LayoutUniforms>.stride, index: 5)
            encoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)

            encoder.setComputePipelineState(integratePipeline)
            encoder.setBuffer(positions, offset: 0, index: 0)
            encoder.setBuffer(velocities, offset: 0, index: 1)
            encoder.setBuffer(forces, offset: 0, index: 2)
            encoder.setBuffer(meta, offset: 0, index: 3)
            encoder.setBytes(&uniforms, length: MemoryLayout<LayoutUniforms>.stride, index: 4)
            encoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
        }

        encoder.setComputePipelineState(reducePipeline)
        encoder.setBuffer(positions, offset: 0, index: 0)
        encoder.setBuffer(velocities, offset: 0, index: 1)
        encoder.setBuffer(stats, offset: 0, index: 2)
        encoder.setBytes(&uniforms, length: MemoryLayout<LayoutUniforms>.stride, index: 3)
        encoder.setThreadgroupMemoryLength(
            MemoryLayout<GraphStats>.stride * Self.threadgroupSize,
            index: 0
        )
        encoder.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)

        encoder.endEncoding()
        return true
    }

    /// Folds the per-threadgroup partials the last completed step wrote.
    ///
    /// Call this after the command buffer has finished. On unified memory the partials are
    /// already visible to the CPU, so this is a handful of reads, not a GPU round trip.
    public func consumeStats() {
        guard statsGroupCount > 0, let buffer = statsBuffer, snapshot.nodeCount > 0 else {
            return
        }
        let partials = buffer.contents().bindMemory(to: GraphStats.self, capacity: statsGroupCount)

        var minBound = SIMD2<Float>(repeating: .greatestFiniteMagnitude)
        var maxBound = SIMD2<Float>(repeating: -.greatestFiniteMagnitude)
        var energy: Float = 0
        for index in 0..<statsGroupCount {
            let partial = partials[index]
            minBound = simd_min(minBound, partial.minBound)
            maxBound = simd_max(maxBound, partial.maxBound)
            energy += partial.energy
        }
        guard minBound.x.isFinite, maxBound.x.isFinite else { return }

        bounds = (minBound, maxBound)
        averageEnergy = energy / Float(snapshot.nodeCount)
    }

    /// Nudges the simulation back into motion, e.g. after the user drags a node.
    public func reheat(to value: Float = 1.4) {
        temperature = max(temperature, value)
        averageEnergy = .greatestFiniteMagnitude
        forcedSteps = Self.forcedStepsAfterDisturbance
    }

    /// Roughly a tenth of a second at 120 Hz: long enough for the reduction to catch up
    /// with reality, short enough to be imperceptible if the graph really was settled.
    private static let forcedStepsAfterDisturbance = 12

    // MARK: - CPU-side access

    /// Live view of node positions.
    ///
    /// On Apple silicon this is the GPU's own allocation, so hit-testing and the
    /// position cache read it with no blit, no staging buffer, and no stall. That zero
    /// copy is the main reason the graph can pick nodes at 120 Hz.
    public var positions: UnsafeBufferPointer<SIMD2<Float>>? {
        guard let buffer = positionsBuffer, snapshot.nodeCount > 0 else { return nil }
        return UnsafeBufferPointer(
            start: buffer.contents().bindMemory(
                to: SIMD2<Float>.self,
                capacity: snapshot.nodeCount
            ),
            count: snapshot.nodeCount
        )
    }

    /// Remembers where every node ended up, so the next ``load(_:)`` can resume from here.
    public func cachePositions() {
        guard let positions else { return }
        lastPositions.removeAll(keepingCapacity: true)
        for (index, node) in snapshot.nodes.enumerated() {
            lastPositions[node.id] = positions[index]
        }
    }

    /// Moves a node under the user's finger and pins it for the duration of the drag.
    public func setPosition(_ position: SIMD2<Float>, forNodeAt index: Int, pinned: Bool) {
        guard index >= 0, index < snapshot.nodeCount,
              let positionsBuffer, let metaBuffer
        else { return }

        positionsBuffer.contents()
            .bindMemory(to: SIMD2<Float>.self, capacity: snapshot.nodeCount)[index] = position

        let meta = metaBuffer.contents()
            .bindMemory(to: NodeMeta.self, capacity: snapshot.nodeCount)
        var flags = NodeFlags(rawValue: meta[index].flags)
        if pinned { flags.insert(.pinned) } else { flags.remove(.pinned) }
        meta[index].flags = flags.rawValue

        markBuffersModified()
        reheat()
    }

    private func refreshBoundsFromPositions() {
        guard let positions else { return }
        var minBound = SIMD2<Float>(repeating: .greatestFiniteMagnitude)
        var maxBound = SIMD2<Float>(repeating: -.greatestFiniteMagnitude)
        for position in positions {
            minBound = simd_min(minBound, position)
            maxBound = simd_max(maxBound, position)
        }
        bounds = (minBound, maxBound)
    }

    /// Discrete GPUs keep a separate copy, so CPU writes have to be published explicitly.
    /// On unified memory there is nothing to publish and this is a no-op.
    private func markBuffersModified() {
        #if os(macOS)
        guard !hasUnifiedMemory else { return }
        if let buffer = positionsBuffer { buffer.didModifyRange(0..<buffer.length) }
        if let buffer = metaBuffer { buffer.didModifyRange(0..<buffer.length) }
        #endif
    }

    // MARK: - Buffers exposed to the renderer

    var renderPositions: MTLBuffer? { positionsBuffer }
    var renderMeta: MTLBuffer? { metaBuffer }
    var renderEdges: MTLBuffer? { edgesBuffer }
    var renderEdgeWeights: MTLBuffer? { edgeWeightsBuffer }

    private var storageMode: MTLResourceOptions {
        // `.storageModeShared` puts the allocation in memory both processors can see. On
        // Apple silicon that is simply the only memory there is, so every buffer is
        // zero-copy. `.storageModeManaged` exists only on macOS, for discrete GPUs that
        // keep their own copy and need CPU writes published explicitly.
        #if os(macOS)
        return hasUnifiedMemory ? .storageModeShared : .storageModeManaged
        #else
        return .storageModeShared
        #endif
    }

    private func makeBuffer<T>(_ values: [T]) -> MTLBuffer? {
        guard !values.isEmpty else { return nil }
        return values.withUnsafeBytes { raw in
            device.makeBuffer(
                bytes: raw.baseAddress!,
                length: raw.count,
                options: storageMode
            )
        }
    }

    /// Metal cannot allocate a zero-length buffer, and an edgeless graph is perfectly
    /// normal, so single-element padding stands in for an empty array.
    private func paddedIfEmpty<T>(_ values: [T]) -> [T] where T: ExpressibleByIntegerLiteral {
        values.isEmpty ? [0] : values
    }

    private func paddedIfEmpty(_ values: [SIMD2<UInt32>]) -> [SIMD2<UInt32>] {
        values.isEmpty ? [SIMD2<UInt32>(0, 0)] : values
    }
}
