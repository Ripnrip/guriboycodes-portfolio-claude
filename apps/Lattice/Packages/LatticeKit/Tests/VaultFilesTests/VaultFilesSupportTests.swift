import Foundation
import Testing
@testable import VaultFiles

@Suite("ContentHash")
struct ContentHashTests {
    @Test("Identical input hashes identically, different input does not")
    func stability() {
        #expect(ContentHash.hash("# Note") == ContentHash.hash("# Note"))
        #expect(ContentHash.hash("# Note") != ContentHash.hash("# Notes"))
        // Change detection has to notice a one-character edit, which is the whole point.
        #expect(ContentHash.hash("a") != ContentHash.hash("b"))
    }

    @Test("Empty input hashes to the offset basis rather than crashing")
    func empty() {
        #expect(!ContentHash.hash("").isEmpty)
    }

    @Test("Hashing a string and its UTF-8 data agree")
    func stringAndDataAgree() {
        let text = "héllo — wörld"
        #expect(ContentHash.hash(text) == ContentHash.hash(of: Data(text.utf8)))
    }
}

@Suite("Vault")
struct VaultTests {
    private let vault = Vault(root: URL(fileURLWithPath: "/tmp/vault"))

    @Test("Round-trips between relative paths and absolute URLs")
    func roundTrip() throws {
        let url = vault.url(for: "Projects/Note.md")
        #expect(vault.relativePath(for: url) == "Projects/Note.md")
    }

    @Test("Rejects a path outside the vault")
    func containment() {
        // Containment is a safety check, not tidiness: a resolved bookmark or a symlink
        // could otherwise let a write land outside the folder the user actually chose.
        #expect(vault.relativePath(for: URL(fileURLWithPath: "/etc/passwd")) == nil)
        #expect(vault.relativePath(for: URL(fileURLWithPath: "/tmp/vault-other/Note.md")) == nil)
        #expect(vault.relativePath(for: URL(fileURLWithPath: "/tmp/vault")) == nil)
    }

    @Test("Normalises traversal before comparing")
    func normalisesTraversal() {
        #expect(vault.relativePath(for: URL(fileURLWithPath: "/tmp/vault/./Note.md")) == "Note.md")
        #expect(vault.relativePath(for: URL(fileURLWithPath: "/tmp/vault/sub/../Note.md")) == "Note.md")
        #expect(vault.relativePath(for: URL(fileURLWithPath: "/tmp/vault/../escape.md")) == nil)
    }
}

@Suite("FileFingerprint")
struct FileFingerprintTests {
    private func fingerprint(size: Int, at date: Date) -> FileFingerprint {
        FileFingerprint(relativePath: "N.md", size: size, modifiedAt: date, contentHash: "abc")
    }

    @Test("Matches on identical metadata")
    func matches() {
        let now = Date()
        #expect(fingerprint(size: 10, at: now).metadataMatches(size: 10, modifiedAt: now))
    }

    @Test("Tolerates sub-millisecond timestamp drift")
    func tolerance() {
        // Filesystems and iCloud disagree about sub-second precision; an exact Date
        // comparison produces spurious mismatches that each cost a file read.
        let now = Date()
        let drifted = now.addingTimeInterval(0.0001)
        #expect(fingerprint(size: 10, at: now).metadataMatches(size: 10, modifiedAt: drifted))
    }

    @Test("Rejects a real size or timestamp change")
    func rejects() {
        let now = Date()
        let print = fingerprint(size: 10, at: now)
        #expect(!print.metadataMatches(size: 11, modifiedAt: now))
        #expect(!print.metadataMatches(size: 10, modifiedAt: now.addingTimeInterval(5)))
    }
}
