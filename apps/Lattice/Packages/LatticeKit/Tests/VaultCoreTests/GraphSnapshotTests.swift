import Testing
@testable import VaultCore

@Suite("GraphSnapshot")
struct GraphSnapshotTests {
    /// Triangle 0-1-2 plus an isolated node 3.
    private func sample() -> GraphSnapshot {
        GraphSnapshot(
            nodes: (0..<4).map { (id: NoteID(rawValue: "n\($0)"), label: "n\($0)", group: 0) },
            edges: [
                .init(source: 0, target: 1, weight: 1),
                .init(source: 1, target: 2, weight: 2),
                .init(source: 0, target: 2, weight: 1),
            ]
        )
    }

    @Test("Counts degree from both endpoints of each edge")
    func degrees() {
        let graph = sample()
        #expect(graph.nodes.map(\.degree) == [2, 2, 2, 0])
    }

    @Test("CSR offsets are a prefix sum of degree and cover every half-edge")
    func csrOffsets() {
        let graph = sample()
        #expect(graph.adjacencyOffsets == [0, 2, 4, 6, 6])
        // Every edge is stored from both ends, so the arrays hold 2 * edgeCount entries.
        #expect(graph.adjacencyNeighbors.count == graph.edges.count * 2)
        #expect(graph.adjacencyWeights.count == graph.edges.count * 2)
    }

    @Test("CSR neighbour slices match the edge list")
    func csrNeighbors() {
        let graph = sample()
        #expect(Set(graph.neighbors(of: 0)) == [1, 2])
        #expect(Set(graph.neighbors(of: 1)) == [0, 2])
        #expect(Set(graph.neighbors(of: 2)) == [0, 1])
        #expect(graph.neighbors(of: 3).isEmpty)
    }

    @Test("Weights travel with their half-edges in both directions")
    func csrWeights() {
        let graph = sample()
        // The 1-2 edge has weight 2 and must read as 2 from either end.
        let fromOne = zip(graph.neighbors(of: 1), weights(graph, of: 1)).first { $0.0 == 2 }
        let fromTwo = zip(graph.neighbors(of: 2), weights(graph, of: 2)).first { $0.0 == 1 }
        #expect(fromOne?.1 == 2)
        #expect(fromTwo?.1 == 2)
    }

    private func weights(_ graph: GraphSnapshot, of index: Int) -> ArraySlice<Float> {
        graph.adjacencyWeights[
            Int(graph.adjacencyOffsets[index])..<Int(graph.adjacencyOffsets[index + 1])
        ]
    }

    @Test("Drops self-loops and out-of-range edges instead of trapping")
    func dropsInvalidEdges() {
        let graph = GraphSnapshot(
            nodes: (0..<2).map { (id: NoteID(rawValue: "n\($0)"), label: "n", group: 0) },
            edges: [
                .init(source: 0, target: 0, weight: 1),   // self-loop
                .init(source: 0, target: 99, weight: 1),  // dangling index
                .init(source: -1, target: 0, weight: 1),  // negative index
                .init(source: 0, target: 1, weight: 1),   // the only good one
            ]
        )
        #expect(graph.edgeCount == 1)
        #expect(graph.nodes.map(\.degree) == [1, 1])
    }

    @Test("Breadth-first neighbourhood respects the hop limit")
    func neighborhood() {
        // Path graph 0-1-2-3.
        let graph = GraphSnapshot(
            nodes: (0..<4).map { (id: NoteID(rawValue: "n\($0)"), label: "n", group: 0) },
            edges: [
                .init(source: 0, target: 1, weight: 1),
                .init(source: 1, target: 2, weight: 1),
                .init(source: 2, target: 3, weight: 1),
            ]
        )
        #expect(graph.neighborhood(around: 0, depth: 0) == [0])
        #expect(graph.neighborhood(around: 0, depth: 1) == [0, 1])
        #expect(graph.neighborhood(around: 0, depth: 2) == [0, 1, 2])
        #expect(graph.neighborhood(around: 0, depth: 99) == [0, 1, 2, 3])
    }

    @Test("Finds orphans and maps ids back to indices")
    func orphansAndLookup() {
        let graph = sample()
        #expect(graph.orphanIndices == [3])
        #expect(graph.nodeIndex(for: NoteID(rawValue: "n2")) == 2)
        #expect(graph.nodeIndex(for: NoteID(rawValue: "nope")) == nil)
    }

    @Test("An empty graph is well-formed rather than a special case")
    func empty() {
        let graph = GraphSnapshot.empty
        #expect(graph.isEmpty)
        #expect(graph.adjacencyOffsets == [0])
        #expect(graph.neighborhood(around: 0, depth: 3).isEmpty)
    }
}
