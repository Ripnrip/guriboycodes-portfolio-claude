import Testing
import VaultCore
@testable import MarkdownKit

@Suite("NoteParser")
struct NoteParserTests {
    private let parser = NoteParser()

    @Test("Title precedence runs frontmatter, then H1, then filename")
    func titlePrecedence() {
        #expect(
            parser.parse("---\ntitle: From Matter\n---\n# From Heading", filename: "File").title
                == "From Matter"
        )
        #expect(parser.parse("# From Heading\n", filename: "File").title == "From Heading")
        #expect(parser.parse("Just body text\n", filename: "File").title == "File")
    }

    @Test("Merges frontmatter tags with body tags and deduplicates")
    func mergesTags() {
        let note = parser.parse(
            """
            ---
            tags: [project, Shared]
            ---
            Body mentions #shared and #new/nested.
            """,
            filename: "N"
        )
        #expect(note.tags.map(\.path) == ["new/nested", "project", "shared"])
    }

    @Test("Link ranges are absolute, so frontmatter does not shift them")
    func linkOffsets() throws {
        let source = "---\nid: x\n---\n[[Target]]"
        let note = parser.parse(source, filename: "N")
        let link = try #require(note.wikilinks.first)
        #expect(link.target == "Target")
        // 14 is just past the closing fence.
        #expect(link.range.lowerBound == 14)
    }

    @Test("Converts wikilinks into store-ready link rows")
    func producesLinks() {
        let note = parser.parse("[[A]] and ![[B]]", filename: "N")
        let links = note.links(from: NoteID(rawValue: "src"))
        #expect(links.map(\.target) == ["A", "B"])
        #expect(links.map(\.kind) == [.wikilink, .embed])
        #expect(links.allSatisfy { $0.source == NoteID(rawValue: "src") })
    }

    @Test("Excerpt skips headings and shows link text, not link markup")
    func excerpt() {
        let note = parser.parse(
            "# Title\n\n> a quote\n\nSee [[Projects/Lattice|the graph app]] for **details**.",
            filename: "N"
        )
        #expect(note.excerpt == "See the graph app for details.")
    }

    @Test("Excerpt truncates long paragraphs with an ellipsis")
    func excerptTruncates() {
        let long = String(repeating: "word ", count: 100)
        let note = parser.parse(long, filename: "N")
        #expect(note.excerpt.count <= 201)
        #expect(note.excerpt.hasSuffix("…"))
    }

    @Test("Word count covers the body only, not the frontmatter")
    func wordCount() {
        let note = parser.parse("---\ntitle: One Two Three Four\n---\nfive six\n", filename: "N")
        #expect(note.wordCount == 2)
    }

    @Test("Aliases come from either the singular or plural key")
    func aliases() {
        #expect(parser.parse("---\naliases: [A, B]\n---\n", filename: "N").aliases == ["A", "B"])
        #expect(parser.parse("---\nalias: Solo\n---\n", filename: "N").aliases == ["Solo"])
    }

    @Test("An empty document parses without crashing")
    func empty() {
        let note = parser.parse("", filename: "Empty")
        #expect(note.title == "Empty")
        #expect(note.wordCount == 0)
        #expect(note.excerpt.isEmpty)
        #expect(note.wikilinks.isEmpty)
    }
}
