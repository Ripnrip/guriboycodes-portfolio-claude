import Testing
import VaultCore
@testable import VaultFiles

@Suite("LinkRewriter")
struct LinkRewriterTests {
    private let forms = LinkRewriter.targetForms(
        relativePath: "Projects/Old Name.md",
        title: "Old Name",
        aliases: ["Legacy"]
    )

    @Test("Rewrites a plain link")
    func plain() {
        let result = LinkRewriter.rewriting(
            "See [[Old Name]] for details.",
            matching: forms,
            to: "Projects/New Name"
        )
        #expect(result == "See [[Projects/New Name]] for details.")
    }

    @Test("Keeps the alias, which is the text the reader sees")
    func preservesAlias() {
        let result = LinkRewriter.rewriting(
            "See [[Old Name|the old thing]].",
            matching: forms,
            to: "New Name"
        )
        #expect(result == "See [[New Name|the old thing]].")
    }

    @Test("Keeps heading and block anchors")
    func preservesAnchors() {
        #expect(
            LinkRewriter.rewriting("[[Old Name#Design]]", matching: forms, to: "New")
                == "[[New#Design]]"
        )
        #expect(
            LinkRewriter.rewriting("[[Old Name#^blk-1]]", matching: forms, to: "New")
                == "[[New#^blk-1]]"
        )
    }

    @Test("Keeps the embed marker")
    func preservesEmbed() {
        #expect(
            LinkRewriter.rewriting("![[Old Name]]", matching: forms, to: "New")
                == "![[New]]"
        )
    }

    @Test("Rewrites every occurrence, including several on one line")
    func multiple() {
        let result = LinkRewriter.rewriting(
            "[[Old Name]] and [[Old Name|again]] and [[Old Name#H]]",
            matching: forms,
            to: "New"
        )
        #expect(result == "[[New]] and [[New|again]] and [[New#H]]")
    }

    @Test("Matches the path, the title, and an alias")
    func matchesEveryForm() {
        #expect(LinkRewriter.rewriting("[[Projects/Old Name]]", matching: forms, to: "N") != nil)
        #expect(LinkRewriter.rewriting("[[Projects/Old Name.md]]", matching: forms, to: "N") != nil)
        #expect(LinkRewriter.rewriting("[[Old Name]]", matching: forms, to: "N") != nil)
        #expect(LinkRewriter.rewriting("[[Legacy]]", matching: forms, to: "N") != nil)
    }

    @Test("Matching ignores case and surrounding whitespace")
    func normalizes() {
        #expect(LinkRewriter.rewriting("[[ old name ]]", matching: forms, to: "N") == "[[N]]")
        #expect(LinkRewriter.rewriting("[[OLD NAME]]", matching: forms, to: "N") == "[[N]]")
    }

    @Test("Leaves a link inside a code fence alone")
    func skipsCodeFences() {
        // The rewrite goes through the scanner precisely so documentation that shows
        // wikilink syntax is not silently rewritten as if it were a real link.
        let source = """
            Real [[Old Name]] here.

            ```markdown
            Example: [[Old Name]]
            ```
            """
        let result = LinkRewriter.rewriting(source, matching: forms, to: "New")
        #expect(result?.contains("Real [[New]] here.") == true)
        #expect(result?.contains("Example: [[Old Name]]") == true)
    }

    @Test("Leaves an inline code span alone")
    func skipsInlineCode() {
        let result = LinkRewriter.rewriting(
            "Write `[[Old Name]]` to link.",
            matching: forms,
            to: "New"
        )
        #expect(result == nil)
    }

    @Test("Returns nil when nothing matched, so no needless write happens")
    func noMatch() {
        #expect(LinkRewriter.rewriting("[[Something Else]]", matching: forms, to: "N") == nil)
        #expect(LinkRewriter.rewriting("No links at all.", matching: forms, to: "N") == nil)
        #expect(LinkRewriter.rewriting("[[Old Name]]", matching: [], to: "N") == nil)
    }

    @Test("Target forms cover path, bare basename, extension-less path, and aliases")
    func targetForms() {
        let forms = LinkRewriter.targetForms(
            relativePath: "A/B/Note.md",
            title: "Note Title",
            aliases: ["Nickname"]
        )
        #expect(forms.contains("a/b/note.md"))
        #expect(forms.contains("a/b/note"))
        #expect(forms.contains("note"))
        #expect(forms.contains("note title"))
        #expect(forms.contains("nickname"))
        #expect(!forms.contains(""))
    }
}
