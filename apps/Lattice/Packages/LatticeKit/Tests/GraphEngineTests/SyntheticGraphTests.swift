import Testing
import VaultCore
@testable import GraphEngine

@Suite("SyntheticGraph")
struct SyntheticGraphTests {
    @Test("Produces a connected graph of the requested size")
    func shape() {
        let graph = SyntheticGraph.barabasiAlbert(nodeCount: 500, edgesPerNode: 2)
        #expect(graph.nodeCount == 500)
        #expect(graph.edgeCount > 0)
        // Preferential attachment links every new node to an existing one, so nothing is
        // orphaned; an orphan here would mean the urn sampling had broken.
        #expect(graph.orphanIndices.isEmpty)
    }

    @Test("Degree distribution is skewed, like a real vault")
    func hasHubs() {
        let graph = SyntheticGraph.barabasiAlbert(nodeCount: 1000, edgesPerNode: 2)
        let degrees = graph.nodes.map(\.degree)
        let mean = Double(degrees.reduce(0, +)) / Double(degrees.count)
        let maximum = degrees.max() ?? 0
        // A uniformly random graph would put the maximum near the mean; a scale-free one
        // puts it far above, which is what makes hub notes read as hubs.
        #expect(Double(maximum) > mean * 4)
    }

    @Test("Is reproducible for a given seed and varies across seeds")
    func deterministic() {
        let a = SyntheticGraph.barabasiAlbert(nodeCount: 200, seed: 1)
        let b = SyntheticGraph.barabasiAlbert(nodeCount: 200, seed: 1)
        let c = SyntheticGraph.barabasiAlbert(nodeCount: 200, seed: 2)
        #expect(a.edges == b.edges)
        #expect(a.edges != c.edges)
    }

    @Test("Degenerate sizes return an empty graph instead of trapping")
    func degenerate() {
        #expect(SyntheticGraph.barabasiAlbert(nodeCount: 0).isEmpty)
        #expect(SyntheticGraph.barabasiAlbert(nodeCount: 1).isEmpty)
    }
}
