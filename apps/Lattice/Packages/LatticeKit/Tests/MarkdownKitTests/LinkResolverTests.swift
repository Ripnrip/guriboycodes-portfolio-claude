import Testing
import VaultCore
@testable import MarkdownKit

@Suite("LinkResolver")
struct LinkResolverTests {
    private func note(
        _ id: String,
        path: String,
        title: String,
        aliases: [String] = []
    ) -> NoteSnapshot {
        NoteSnapshot(
            id: NoteID(rawValue: id),
            relativePath: path,
            title: title,
            aliases: aliases
        )
    }

    private func link(from source: String, to target: String) -> LinkSnapshot {
        LinkSnapshot(
            source: NoteID(rawValue: source),
            target: target,
            kind: .wikilink,
            range: 0..<1
        )
    }

    @Test("Resolves by path, title, and alias")
    func resolvesEachWay() {
        let resolver = LinkResolver(notes: [
            note("a", path: "Projects/Lattice.md", title: "Lattice", aliases: ["The Graph App"])
        ])
        #expect(resolver.resolve("Projects/Lattice.md") == NoteID(rawValue: "a"))
        #expect(resolver.resolve("Projects/Lattice") == NoteID(rawValue: "a"))
        #expect(resolver.resolve("Lattice") == NoteID(rawValue: "a"))
        #expect(resolver.resolve("The Graph App") == NoteID(rawValue: "a"))
    }

    @Test("Resolution ignores case and surrounding whitespace")
    func caseAndWhitespace() {
        let resolver = LinkResolver(notes: [note("a", path: "A.md", title: "Alpha")])
        #expect(resolver.resolve("  alpha  ") == NoteID(rawValue: "a"))
        #expect(resolver.resolve("ALPHA") == NoteID(rawValue: "a"))
    }

    @Test("A basename shared by two notes stays unresolved rather than guessing")
    func ambiguousBasename() {
        let resolver = LinkResolver(notes: [
            note("a", path: "One/Shared.md", title: "First"),
            note("b", path: "Two/Shared.md", title: "Second"),
        ])
        #expect(resolver.resolve("Shared") == nil)
        // The full path is still unambiguous.
        #expect(resolver.resolve("One/Shared") == NoteID(rawValue: "a"))
    }

    @Test("An unknown target is unresolved, not an error")
    func dangling() {
        let resolver = LinkResolver(notes: [note("a", path: "A.md", title: "Alpha")])
        #expect(resolver.resolve("Nonexistent") == nil)
        #expect(resolver.resolve("") == nil)
    }

    @Test("Partitions links into resolved and dangling")
    func partitions() {
        let resolver = LinkResolver(notes: [note("a", path: "A.md", title: "Alpha")])
        let (resolved, dangling) = resolver.resolveAll([
            link(from: "b", to: "Alpha"),
            link(from: "b", to: "Ghost"),
        ])
        #expect(resolved.map(\.target) == [NoteID(rawValue: "a")])
        #expect(dangling.map(\.target) == ["Ghost"])
    }

    // MARK: Graph construction

    @Test("Collapses repeated links into one weighted edge")
    func weightsAccumulate() {
        let notes = [
            note("a", path: "A.md", title: "Alpha"),
            note("b", path: "B.md", title: "Beta"),
        ]
        let graph = LinkResolver.buildGraph(
            notes: notes,
            links: [
                link(from: "a", to: "Beta"),
                link(from: "a", to: "Beta"),
                link(from: "b", to: "Alpha"),
            ],
            includeDangling: false
        )
        #expect(graph.nodeCount == 2)
        #expect(graph.edgeCount == 1)
        // Three references between the same pair, in either direction, weigh 3.
        #expect(graph.edges[0].weight == 3)
    }

    @Test("Dangling links become one placeholder node per distinct target")
    func placeholders() {
        let notes = [note("a", path: "A.md", title: "Alpha")]
        let graph = LinkResolver.buildGraph(
            notes: notes,
            links: [
                link(from: "a", to: "Unwritten"),
                link(from: "a", to: "unwritten"),
                link(from: "a", to: "Also Missing"),
            ]
        )
        #expect(graph.nodeCount == 3)
        // Placeholders are marked with a negative group so the renderer can hollow them.
        #expect(graph.nodes.filter { $0.group == -1 }.count == 2)
        #expect(graph.edgeCount == 2)
    }

    @Test("Dangling links can be excluded entirely")
    func excludeDangling() {
        let graph = LinkResolver.buildGraph(
            notes: [note("a", path: "A.md", title: "Alpha")],
            links: [link(from: "a", to: "Ghost")],
            includeDangling: false
        )
        #expect(graph.nodeCount == 1)
        #expect(graph.edgeCount == 0)
    }

    @Test("A note linking to itself produces no edge")
    func selfLink() {
        let graph = LinkResolver.buildGraph(
            notes: [note("a", path: "A.md", title: "Alpha")],
            links: [link(from: "a", to: "Alpha")]
        )
        #expect(graph.edgeCount == 0)
    }

    @Test("Edge order is deterministic across builds")
    func deterministic() {
        let notes = (0..<8).map { note("n\($0)", path: "n\($0).md", title: "N\($0)") }
        let links = (0..<8).flatMap { i in
            (0..<8).filter { $0 != i }.map { link(from: "n\(i)", to: "N\($0)") }
        }
        let first = LinkResolver.buildGraph(notes: notes, links: links)
        let second = LinkResolver.buildGraph(notes: notes, links: links)
        #expect(first.edges == second.edges)
        #expect(first.adjacencyOffsets == second.adjacencyOffsets)
    }
}
