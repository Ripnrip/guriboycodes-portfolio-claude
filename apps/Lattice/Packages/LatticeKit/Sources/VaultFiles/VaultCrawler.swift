import Foundation

/// Walks a vault folder and reports what changed since the index last saw it.
///
/// The crawl — not the file watcher — is what makes the index correct. macOS has FSEvents
/// and iOS has nothing comparable, so live watching is treated as a latency optimisation
/// and an incremental crawl on activation is the guarantee. That is only affordable
/// because the crawl is cheap: metadata comes free from the directory enumeration, and a
/// file is read only when its size or timestamp disagrees with the stored fingerprint.
public struct VaultCrawler: Sendable {
    /// Extensions treated as notes. Everything else in the folder is ignored, so a vault
    /// may hold attachments without them appearing in the graph.
    public static let noteExtensions: Set<String> = ["md", "markdown"]

    /// Directories skipped regardless of their hidden flag.
    ///
    /// Dot-directories are already excluded by `.skipsHiddenFiles`, but being explicit
    /// about these keeps a mis-set hidden flag from pulling a tool's internals into the
    /// graph.
    public static let ignoredDirectories: Set<String> = [
        ".obsidian", ".git", ".trash", ".smart-env", "node_modules",
    ]

    private let io: VaultFileIO

    public init(io: VaultFileIO = VaultFileIO()) {
        self.io = io
    }

    public func scan(
        _ vault: Vault,
        known: [String: FileFingerprint]
    ) throws -> VaultChangeSet {
        var changes = VaultChangeSet()
        var seen = Set<String>()

        for url in try noteURLs(in: vault) {
            guard let relativePath = vault.relativePath(for: url) else { continue }
            seen.insert(relativePath)

            let metadata: (size: Int, modifiedAt: Date)
            do {
                metadata = try io.metadata(of: url)
            } catch {
                // A file that vanished between enumeration and stat is simply not there;
                // the next crawl will report it removed.
                continue
            }

            if let previous = known[relativePath],
               previous.metadataMatches(size: metadata.size, modifiedAt: metadata.modifiedAt) {
                changes.unchangedPaths.append(relativePath)
                continue
            }

            // Cheap check disagreed, so pay for the read and compare content.
            let content: String
            do {
                content = try io.read(url)
            } catch {
                continue
            }
            let fingerprint = FileFingerprint(
                relativePath: relativePath,
                size: metadata.size,
                modifiedAt: metadata.modifiedAt,
                contentHash: ContentHash.hash(content)
            )

            guard let previous = known[relativePath] else {
                changes.added.append(ScannedFile(fingerprint: fingerprint, content: content))
                continue
            }
            if previous.contentHash == fingerprint.contentHash {
                changes.touched.append(fingerprint)
            } else {
                changes.modified.append(ScannedFile(fingerprint: fingerprint, content: content))
            }
        }

        changes.removedPaths = known.keys.filter { !seen.contains($0) }.sorted()

        // Sorted so a crawl is reproducible and diffs between runs are readable.
        changes.added.sort { $0.relativePath < $1.relativePath }
        changes.modified.sort { $0.relativePath < $1.relativePath }
        changes.touched.sort { $0.relativePath < $1.relativePath }
        changes.unchangedPaths.sort()
        return changes
    }

    /// Every note file in the vault, depth-first, skipping hidden and tool directories.
    func noteURLs(in vault: Vault) throws -> [URL] {
        let manager = FileManager.default
        guard let enumerator = manager.enumerator(
            at: vault.root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        var results: [URL] = []
        for case let url as URL in enumerator {
            let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory)
                ?? false
            if isDirectory {
                if Self.ignoredDirectories.contains(url.lastPathComponent) {
                    enumerator.skipDescendants()
                }
                continue
            }
            guard Self.noteExtensions.contains(url.pathExtension.lowercased()) else { continue }
            results.append(url)
        }
        return results
    }
}
