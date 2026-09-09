import MetalKit
import SwiftUI
import VaultCore
import simd

/// Observable state for the graph, owned by the app and read by SwiftUI.
///
/// The heavy state — positions, velocities, GPU buffers — deliberately stays inside
/// ``GraphSimulation``. Only the few values SwiftUI actually renders live here, so a
/// hover does not invalidate a view hierarchy sixty times a second.
@MainActor
@Observable
public final class GraphViewModel {
    public private(set) var snapshot: GraphSnapshot = .empty
    /// The note under the pointer, for a hover label.
    public private(set) var hoveredNode: GraphSnapshot.Node?
    /// The note the user opened.
    public private(set) var selectedNode: GraphSnapshot.Node?
    /// Set when Metal is unavailable or the shaders fail to load.
    public private(set) var failure: String?

    public var style: GraphStyle = .dark
    public var parameters: GraphLayoutParameters = .default {
        didSet { renderer?.simulation.parameters = parameters }
    }

    /// Called when the user opens a node, so the app can navigate to the note.
    public var onOpenNote: (@MainActor (NoteID) -> Void)?

    private(set) var renderer: GraphRenderer?

    public init() {}

    /// Builds the Metal stack. Safe to call more than once; later calls are ignored.
    func prepare(pixelFormat: MTLPixelFormat, sampleCount: Int) {
        guard renderer == nil, failure == nil else { return }
        do {
            let simulation = try GraphSimulation()
            simulation.parameters = parameters
            let renderer = try GraphRenderer(
                simulation: simulation,
                pixelFormat: pixelFormat,
                sampleCount: sampleCount
            )
            renderer.style = style
            renderer.onFirstSettle = { [weak renderer] in
                renderer?.fitToContent()
            }
            self.renderer = renderer
            if !snapshot.isEmpty {
                simulation.load(snapshot)
            }
        } catch {
            failure = error.localizedDescription
        }
    }

    /// Replaces the displayed graph, keeping surviving nodes where they are.
    public func load(_ snapshot: GraphSnapshot) {
        self.snapshot = snapshot
        hoveredNode = nil
        selectedNode = nil
        renderer?.simulation.load(snapshot)
        renderer?.selectedNode = nil
        renderer?.highlightedNode = nil
        renderer?.resetAutoFit()
        renderer?.resume()
    }

    /// Frames the whole graph.
    public func fitToContent() {
        renderer?.fitToContent()
        renderer?.setNeedsRedraw()
    }

    /// Restarts the layout from a hot state, e.g. after changing parameters.
    public func reheat() {
        renderer?.resume()
    }

    fileprivate func node(at index: Int) -> GraphSnapshot.Node? {
        guard index >= 0, index < snapshot.nodes.count else { return nil }
        return snapshot.nodes[index]
    }
}

/// The graph itself: a Metal view bridged into SwiftUI.
public struct GraphView: PlatformViewRepresentable {
    // A plain reference is enough: `GraphViewModel` is `@Observable`, so reading its
    // properties in a body establishes the dependency without a property wrapper.
    private let model: GraphViewModel

    public init(model: GraphViewModel) {
        self.model = model
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }

    #if os(macOS)
    public func makeNSView(context: Context) -> GraphMetalView {
        makeGraphView(context: context)
    }

    public func updateNSView(_ view: GraphMetalView, context: Context) {
        applyUpdates(to: view)
    }
    #else
    public func makeUIView(context: Context) -> GraphMetalView {
        makeGraphView(context: context)
    }

    public func updateUIView(_ view: GraphMetalView, context: Context) {
        applyUpdates(to: view)
    }
    #endif

    private func makeGraphView(context: Context) -> GraphMetalView {
        model.prepare(
            pixelFormat: .bgra8Unorm,
            sampleCount: GraphMetalView.preferredSampleCount
        )
        // When Metal failed to start the view is inert and the overlay explains why.
        let view = GraphMetalView(renderer: model.renderer)
        view.interactionDelegate = context.coordinator
        return view
    }

    private func applyUpdates(to view: GraphMetalView) {
        guard let renderer = model.renderer else { return }
        renderer.attachedView = view
        if renderer.style != model.style {
            renderer.style = model.style
            renderer.setNeedsRedraw()
        }
    }

    /// Translates view-layer interaction into model updates.
    @MainActor
    public final class Coordinator: GraphInteractionDelegate {
        private let model: GraphViewModel

        init(model: GraphViewModel) {
            self.model = model
        }

        public func graphDidHover(nodeAt index: Int?) {
            model.setHovered(index.flatMap { model.node(at: $0) })
        }

        public func graphDidActivate(nodeAt index: Int) {
            guard let node = model.node(at: index) else { return }
            model.setSelected(node)
            // A placeholder stands for a note that does not exist yet, so opening it is
            // the app's cue to offer creating it rather than to navigate.
            model.onOpenNote?(node.id)
        }

        public func graphDidClearSelection() {
            model.setSelected(nil)
        }
    }
}

extension GraphViewModel {
    fileprivate func setHovered(_ node: GraphSnapshot.Node?) {
        hoveredNode = node
    }

    fileprivate func setSelected(_ node: GraphSnapshot.Node?) {
        selectedNode = node
    }
}

// MARK: - Ready-to-use surface

/// The graph plus the chrome that makes it usable: a hover label, a fit control, and a
/// clear failure state when Metal is unavailable.
public struct GraphCanvas: View {
    private let model: GraphViewModel

    public init(model: GraphViewModel) {
        self.model = model
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            if let failure = model.failure {
                ContentUnavailableView(
                    "Graph unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(failure)
                )
            } else {
                GraphView(model: model)
                    .ignoresSafeArea()

                if let hovered = model.hoveredNode {
                    Text(hovered.label)
                        .font(.callout.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.regularMaterial, in: .rect(cornerRadius: 8))
                        .padding(12)
                        .transition(.opacity)
                        .accessibilityHidden(true)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if model.failure == nil {
                Button {
                    model.fitToContent()
                } label: {
                    Label("Fit graph", systemImage: "arrow.up.left.and.arrow.down.right")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .padding(12)
                .accessibilityLabel("Fit graph to window")
            }
        }
        .animation(.easeOut(duration: 0.15), value: model.hoveredNode?.id)
    }
}

extension GraphViewModel {
    /// A model preloaded with a synthetic vault, for previews and first run.
    public static func demo(nodeCount: Int = 400) -> GraphViewModel {
        let model = GraphViewModel()
        model.load(SyntheticGraph.barabasiAlbert(nodeCount: nodeCount))
        return model
    }
}

#Preview("Graph — synthetic vault") {
    GraphCanvas(model: .demo())
        .frame(width: 900, height: 640)
}

#Preview("Graph — empty vault") {
    GraphCanvas(model: GraphViewModel())
        .frame(width: 600, height: 400)
}
