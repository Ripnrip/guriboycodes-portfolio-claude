import Testing
@testable import GraphEngine

@Suite("GraphLayoutParameters")
struct GraphLayoutParametersTests {
    @Test("Repulsion grows with graph size so large graphs do not collapse")
    func scalesWithNodeCount() {
        let base = GraphLayoutParameters.default
        let small = base.normalized(forNodeCount: 100)
        let large = base.normalized(forNodeCount: 10_000)
        #expect(large.repulsion > small.repulsion)
        #expect(small.repulsion > base.repulsion)
    }

    @Test("Ideal edge length stays within sane bounds at both extremes")
    func idealLengthIsClamped() {
        let base = GraphLayoutParameters.default
        let tiny = base.normalized(forNodeCount: 2)
        let huge = base.normalized(forNodeCount: 1_000_000)
        #expect(tiny.idealLength >= base.idealLength * 0.6)
        #expect(huge.idealLength <= base.idealLength * 2.5)
    }

    @Test("A trivial graph is left alone")
    func passesThroughTinyGraphs() {
        let base = GraphLayoutParameters.default
        #expect(base.normalized(forNodeCount: 1) == base)
        #expect(base.normalized(forNodeCount: 0) == base)
    }
}
