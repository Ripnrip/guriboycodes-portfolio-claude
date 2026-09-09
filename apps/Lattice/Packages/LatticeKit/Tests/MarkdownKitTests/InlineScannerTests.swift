import Testing
import VaultCore
@testable import MarkdownKit

@Suite("InlineScanner")
struct InlineScannerTests {
    private let scanner = InlineScanner()

    // MARK: Wikilinks

    @Test("Finds plain links and records exact UTF-16 ranges")
    func plainLink() throws {
        let result = scanner.scan("[[A]]")
        let link = try #require(result.wikilinks.first)
        #expect(link.target == "A")
        #expect(link.range == 0..<5)
        #expect(!link.isEmbed)
        #expect(link.kind == .wikilink)
    }

    @Test("Distinguishes an embed from a link")
    func embed() throws {
        let result = scanner.scan("![[A]]")
        let link = try #require(result.wikilinks.first)
        #expect(link.isEmbed)
        #expect(link.kind == .embed)
        #expect(link.range == 0..<6)
    }

    @Test("Splits alias, heading, and block anchors")
    func anchorsAndAliases() {
        let result = scanner.scan("[[Note|Shown]] [[Note#Heading]] [[Note#^blk-1]]")
        #expect(result.wikilinks.count == 3)
        #expect(result.wikilinks[0].alias == "Shown")
        #expect(result.wikilinks[0].anchor == .wholeNote)
        #expect(result.wikilinks[1].anchor == .heading("Heading"))
        #expect(result.wikilinks[2].anchor == .block("blk-1"))
        #expect(result.wikilinks.allSatisfy { $0.target == "Note" })
    }

    @Test("The alias pipe binds loosest, so a pipe in the alias survives")
    func aliasKeepsLaterPipes() throws {
        let result = scanner.scan("[[A#H|B|C]]")
        let link = try #require(result.wikilinks.first)
        #expect(link.target == "A")
        #expect(link.anchor == .heading("H"))
        #expect(link.alias == "B|C")
    }

    @Test("A same-note block reference has an empty target")
    func sameNoteReference() throws {
        let result = scanner.scan("[[#^blk]]")
        let link = try #require(result.wikilinks.first)
        #expect(link.target.isEmpty)
        #expect(link.anchor == .block("blk"))
    }

    @Test("Brackets that never close, or close on a later line, are not links")
    func unterminated() {
        #expect(scanner.scan("[[A").wikilinks.isEmpty)
        #expect(scanner.scan("[[A\nB]]").wikilinks.isEmpty)
    }

    @Test("A backslash escapes the brackets")
    func escaped() {
        #expect(scanner.scan(#"\[[NotALink]]"#).wikilinks.isEmpty)
    }

    // MARK: Tags

    @Test("Finds a nested tag with its exact range")
    func nestedTag() throws {
        let result = scanner.scan("Tagged #area/work here")
        let tag = try #require(result.tags.first)
        #expect(tag.tag.path == "area/work")
        #expect(tag.range == 7..<17)
    }

    @Test("A hash needs a boundary before it, so C# and id#3 are not tags")
    func tagBoundaries() {
        #expect(scanner.scan("Written in C#").tags.isEmpty)
        #expect(scanner.scan("issue id#3 here").tags.isEmpty)
    }

    @Test("A purely numeric run is a number, not a tag")
    func numericIsNotATag() {
        #expect(scanner.scan("see #1 and #2").tags.isEmpty)
        #expect(scanner.scan("see #v2").tags.count == 1)
    }

    @Test("Trailing punctuation is trimmed off the tag")
    func trailingPunctuation() throws {
        let result = scanner.scan("about #work.")
        let tag = try #require(result.tags.first)
        #expect(tag.tag.path == "work")
        // The trailing period is outside the token's range.
        #expect(tag.range == 6..<11)
    }

    // MARK: Headings vs tags

    @Test("`# x` is a heading and `#x` is a tag")
    func headingVersusTag() {
        let heading = scanner.scan("# Heading")
        #expect(heading.headings.first?.level == 1)
        #expect(heading.headings.first?.text == "Heading")
        #expect(heading.tags.isEmpty)

        let tag = scanner.scan("#heading")
        #expect(tag.headings.isEmpty)
        #expect(tag.tags.first?.tag.path == "heading")
    }

    @Test("Reads heading levels one through six")
    func headingLevels() {
        let result = scanner.scan("# a\n## b\n###### c\n####### d")
        #expect(result.headings.map(\.level) == [1, 2, 6])
    }

    // MARK: Code awareness

    @Test("Ignores everything inside a fenced code block")
    func fencedCode() {
        let source = """
        ```
        #nope [[NotALink]]
        ```
        """
        let result = scanner.scan(source)
        #expect(result.tags.isEmpty)
        #expect(result.wikilinks.isEmpty)
    }

    @Test("A longer closing fence still closes the block")
    func tildeFence() {
        let result = scanner.scan("~~~\n#nope\n~~~\n#yes")
        #expect(result.tags.map(\.tag.path) == ["yes"])
    }

    @Test("Ignores an inline code span")
    func inlineCode() {
        #expect(scanner.scan("run `#nope` please").tags.isEmpty)
        #expect(scanner.scan("run ``a `#nope` b`` please").tags.isEmpty)
    }

    @Test("Ignores an indented code block")
    func indentedCode() {
        #expect(scanner.scan("    #nope [[NotALink]]").tags.isEmpty)
    }

    // MARK: Block identifiers

    @Test("Recognises a trailing block id and the block it names")
    func blockID() throws {
        let result = scanner.scan("This is a block ^abc123\n")
        let block = try #require(result.blockIDs.first)
        #expect(block.identifier == "abc123")
        #expect(block.range == 16..<23)
        #expect(block.blockRange == 0..<15)
    }

    @Test("Finds a block id on an unterminated final line")
    func blockIDAtEOF() {
        #expect(scanner.scan("Last line ^zz").blockIDs.first?.identifier == "zz")
    }

    @Test("A caret without preceding whitespace is not a block id")
    func caretIsNotAlwaysABlockID() {
        #expect(scanner.scan("x^2\n").blockIDs.isEmpty)
        #expect(scanner.scan("^leading\n").blockIDs.isEmpty)
    }

    // MARK: Offsets

    @Test("Scanning from an offset keeps ranges in whole-document coordinates")
    func honorsStartOffset() throws {
        let source = "---\nid: x\n---\n[[A]]"
        let result = scanner.scan(source, from: 14)
        let link = try #require(result.wikilinks.first)
        #expect(link.range == 14..<19)
    }
}
