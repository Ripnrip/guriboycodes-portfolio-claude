import Foundation
import Testing
import VaultFiles

/// A throwaway vault on disk, for crawler tests.
///
/// Real files rather than a mocked filesystem: the crawler's whole job is reconciling
/// against actual directory metadata, and a fake that returns whatever sizes and
/// timestamps the test wants would verify nothing about the part that breaks.
final class TempVault {
    let root: URL
    let vault: Vault
    private let io = VaultFileIO()

    init() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("lattice-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        vault = Vault(root: root)
    }

    deinit {
        try? FileManager.default.removeItem(at: root)
    }

    @discardableResult
    func write(_ relativePath: String, _ contents: String) throws -> URL {
        let url = vault.url(for: relativePath)
        try io.write(contents, to: url)
        return url
    }

    func remove(_ relativePath: String) throws {
        try io.delete(vault.url(for: relativePath))
    }

    func read(_ relativePath: String) throws -> String {
        try io.read(vault.url(for: relativePath))
    }

    func makeDirectory(_ relativePath: String) throws {
        try FileManager.default.createDirectory(
            at: root.appendingPathComponent(relativePath, isDirectory: true),
            withIntermediateDirectories: true
        )
    }

    /// Forces a file's modification date without touching its bytes — the iCloud case.
    func touch(_ relativePath: String, to date: Date) throws {
        try FileManager.default.setAttributes(
            [.modificationDate: date],
            ofItemAtPath: vault.url(for: relativePath).path
        )
    }

    func scan(known: [String: FileFingerprint] = [:]) throws -> VaultChangeSet {
        try VaultCrawler().scan(vault, known: known)
    }

    /// Fingerprints keyed by path, as the index would store them.
    func fingerprints(from changes: VaultChangeSet) -> [String: FileFingerprint] {
        var result: [String: FileFingerprint] = [:]
        for file in changes.added + changes.modified {
            result[file.relativePath] = file.fingerprint
        }
        for fingerprint in changes.touched {
            result[fingerprint.relativePath] = fingerprint
        }
        return result
    }
}
