import GraphEngine
import SwiftUI
import VaultCore

/// The Phase 1 shell: the graph, a size control for exercising it, and a readout of what
/// the pointer is over.
///
/// The vault, editor, and sidebar arrive in Phase 2; until then the graph is fed by
/// ``SyntheticGraph`` so the engine can be driven and profiled on its own.
struct ContentView: View {
    // `@Bindable` so the layout sliders can bind straight into the observable model.
    @Bindable var model: GraphViewModel

    @State private var nodeCount: Double = 600
    @State private var showsInspector = true
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            graph
        }
    }

    private var graph: some View {
        GraphCanvas(model: model)
            .background(Color.black)
            .inspector(isPresented: $showsInspector) {
                inspector
                    .inspectorColumnWidth(min: 240, ideal: 280, max: 360)
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        showsInspector.toggle()
                    } label: {
                        Label("Inspector", systemImage: "sidebar.trailing")
                    }
                }
            }
            .onAppear { applyStyle() }
            .onChange(of: colorScheme) { _, _ in applyStyle() }
            .navigationTitle("Lattice")
    }

    private var inspector: some View {
        Form {
            Section("Graph") {
                LabeledContent("Notes", value: model.snapshot.nodeCount.formatted())
                LabeledContent("Links", value: model.snapshot.edgeCount.formatted())
                LabeledContent("Unlinked", value: model.snapshot.orphanIndices.count.formatted())
            }

            Section("Under the pointer") {
                if let hovered = model.hoveredNode {
                    LabeledContent("Note", value: hovered.label)
                    LabeledContent("Links", value: hovered.degree.formatted())
                } else {
                    Text("Hover a node")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Synthetic vault") {
                // Phase 1 has no file layer yet, so this stands in for a real vault and
                // makes it easy to see how the layout behaves as the graph grows.
                VStack(alignment: .leading) {
                    Slider(value: $nodeCount, in: 50...20_000, step: 50) {
                        Text("Notes")
                    }
                    Text("\(Int(nodeCount)) notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Button("Regenerate") {
                    model.load(SyntheticGraph.barabasiAlbert(nodeCount: Int(nodeCount)))
                }
                Button("Fit to window") { model.fitToContent() }
            }

            Section("Layout") {
                slider("Link length", value: $model.parameters.idealLength, in: 20...160)
                slider("Repulsion", value: $model.parameters.repulsion, in: 200...3000)
                slider("Damping", value: $model.parameters.damping, in: 0.5...0.98)
            }
        }
        .formStyle(.grouped)
        .onChange(of: model.parameters) { _, _ in model.reheat() }
    }

    private func slider(
        _ title: String,
        value: Binding<Float>,
        in range: ClosedRange<Float>
    ) -> some View {
        VStack(alignment: .leading) {
            Text(title)
            Slider(value: value, in: range)
        }
    }

    private func applyStyle() {
        model.style = colorScheme == .dark ? .dark : .light
    }
}

#Preview {
    ContentView(model: .demo(nodeCount: 300))
        .frame(width: 1100, height: 700)
}
