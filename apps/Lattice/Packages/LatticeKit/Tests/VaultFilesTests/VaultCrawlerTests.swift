import Foundation
import Testing
@testable import VaultFiles

@Suite("VaultCrawler")
struct VaultCrawlerTests {
    @Test("A first crawl reports every note as added")
    func firstCrawl() throws {
        let temp = try TempVault()
        try temp.write("One.md", "# One")
        try temp.write("Two.md", "# Two")

        let changes = try temp.scan()
        #expect(changes.added.map(\.relativePath) == ["One.md", "Two.md"])
        #expect(changes.modified.isEmpty)
        #expect(changes.removedPaths.isEmpty)
        #expect(changes.invalidatesLinkGraph)
    }

    @Test("Content comes back attached, so a changed file is read only once")
    func carriesContent() throws {
        let temp = try TempVault()
        try temp.write("One.md", "# Hello")
        let changes = try temp.scan()
        #expect(changes.added.first?.content == "# Hello")
    }

    @Test("Finds notes in subdirectories")
    func recurses() throws {
        let temp = try TempVault()
        try temp.write("Projects/Deep/Note.md", "# Deep")
        let changes = try temp.scan()
        #expect(changes.added.map(\.relativePath) == ["Projects/Deep/Note.md"])
    }

    @Test("Ignores non-note files and tool directories")
    func ignoresNonNotes() throws {
        let temp = try TempVault()
        try temp.write("Note.md", "# Note")
        try temp.write("Note.markdown", "# Also a note")
        try temp.write("image.png", "not markdown")
        try temp.write("notes.txt", "not markdown")
        try temp.write(".obsidian/workspace.md", "tool internals")
        try temp.write("node_modules/pkg/readme.md", "dependency")

        let paths = try temp.scan().added.map(\.relativePath)
        #expect(paths == ["Note.markdown", "Note.md"])
    }

    @Test("An unchanged file is never reopened")
    func unchangedIsSkipped() throws {
        let temp = try TempVault()
        try temp.write("One.md", "# One")
        let first = try temp.scan()
        let known = temp.fingerprints(from: first)

        let second = try temp.scan(known: known)
        #expect(second.isEmpty)
        #expect(second.unchangedPaths == ["One.md"])
        #expect(second.added.isEmpty)
        #expect(!second.invalidatesLinkGraph)
    }

    @Test("A changed file is reported modified, not added")
    func modified() throws {
        let temp = try TempVault()
        try temp.write("One.md", "# One")
        let known = temp.fingerprints(from: try temp.scan())

        try temp.write("One.md", "# One, revised and definitely longer")
        let changes = try temp.scan(known: known)
        #expect(changes.modified.map(\.relativePath) == ["One.md"])
        #expect(changes.added.isEmpty)
        #expect(changes.invalidatesLinkGraph)
    }

    @Test("A timestamp change with identical bytes is touched, not modified")
    func touchedNotModified() throws {
        // This is the iCloud case: the sync daemon rewrites modification dates on files it
        // has merely re-downloaded. Treating those as modified would re-parse the whole
        // vault after every sync.
        let temp = try TempVault()
        try temp.write("One.md", "# Stable content")
        let known = temp.fingerprints(from: try temp.scan())

        try temp.touch("One.md", to: Date().addingTimeInterval(500))
        let changes = try temp.scan(known: known)

        #expect(changes.touched.map(\.relativePath) == ["One.md"])
        #expect(changes.modified.isEmpty)
        #expect(changes.added.isEmpty)
        // Nothing to re-parse, and crucially no reason to rebuild the link graph.
        #expect(changes.needingParse.isEmpty)
        #expect(!changes.invalidatesLinkGraph)
        #expect(!changes.isEmpty)
    }

    @Test("A deleted file is reported removed")
    func removed() throws {
        let temp = try TempVault()
        try temp.write("One.md", "# One")
        try temp.write("Two.md", "# Two")
        let known = temp.fingerprints(from: try temp.scan())

        try temp.remove("Two.md")
        let changes = try temp.scan(known: known)
        #expect(changes.removedPaths == ["Two.md"])
        #expect(changes.unchangedPaths == ["One.md"])
    }

    @Test("A moved file reads as a removal plus an addition")
    func moved() throws {
        let temp = try TempVault()
        try temp.write("One.md", "# One")
        let known = temp.fingerprints(from: try temp.scan())

        try temp.remove("One.md")
        try temp.write("Moved/One.md", "# One")
        let changes = try temp.scan(known: known)

        #expect(changes.removedPaths == ["One.md"])
        #expect(changes.added.map(\.relativePath) == ["Moved/One.md"])
    }

    @Test("An empty vault crawls cleanly")
    func emptyVault() throws {
        let temp = try TempVault()
        try temp.makeDirectory("Empty")
        let changes = try temp.scan()
        #expect(changes.isEmpty)
        #expect(changes.seenPaths.isEmpty)
    }
}
