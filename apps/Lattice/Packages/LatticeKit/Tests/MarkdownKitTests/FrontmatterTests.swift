import Testing
@testable import MarkdownKit

@Suite("Frontmatter")
struct FrontmatterTests {
    @Test("Reads scalars, inline lists, and block lists")
    func parsesSupportedShapes() throws {
        let source = """
        ---
        id: abc-123
        title: My Note
        aliases: [Foo, Bar]
        tags:
          - project
          - area/work
        pinned: true
        ---
        Body text.
        """
        let matter = Frontmatter.parse(source)
        #expect(matter.id == "abc-123")
        #expect(matter.title == "My Note")
        #expect(matter.aliases == ["Foo", "Bar"])
        #expect(matter.tagStrings == ["project", "area/work"])
        #expect(matter["pinned"]?.boolValue == true)
    }

    @Test("Body offset lands just past the closing fence")
    func bodyOffset() {
        let source = "---\nid: x\n---\nHello"
        let matter = Frontmatter.parse(source)
        let body = String(decoding: Array(source.utf16)[matter.bodyStartOffset...], as: UTF16.self)
        #expect(body == "Hello")
    }

    @Test("A quoted value keeps its colon")
    func quotedColon() {
        let matter = Frontmatter.parse("---\ntitle: \"Ratios: a study\"\n---\n")
        #expect(matter.title == "Ratios: a study")
    }

    @Test("Strips an inline comment only from an unquoted value")
    func inlineComments() {
        let matter = Frontmatter.parse("---\na: plain # note\nb: \"kept # here\"\n---\n")
        #expect(matter["a"]?.stringValue == "plain")
        #expect(matter["b"]?.stringValue == "kept # here")
    }

    @Test("A horizontal rule mid-document is not frontmatter")
    func rulesAreNotFrontmatter() {
        let source = "# Title\n\n---\n\nSome text\n"
        let matter = Frontmatter.parse(source)
        #expect(matter.values.isEmpty)
        #expect(matter.bodyStartOffset == 0)
    }

    @Test("An unterminated block is ignored rather than eating the note")
    func unterminated() {
        let matter = Frontmatter.parse("---\nid: x\nstill going\n")
        #expect(matter.values.isEmpty)
        #expect(matter.bodyStartOffset == 0)
    }

    @Test("Keys are case-insensitive")
    func caseInsensitiveKeys() {
        let matter = Frontmatter.parse("---\nTitle: Hello\n---\n")
        #expect(matter["TITLE"]?.stringValue == "Hello")
        #expect(matter.title == "Hello")
    }

    @Test("A note with no frontmatter parses to empty with a zero offset")
    func none() {
        let matter = Frontmatter.parse("Just text\n")
        #expect(matter.values.isEmpty)
        #expect(matter.bodyStartOffset == 0)
    }
}
