import Foundation

/// A vault is a folder of Markdown files.
///
/// There is no proprietary container and no database of record — opening a vault means
/// pointing at a directory, which is what lets Obsidian and Lattice hold the same one.
public struct Vault: Sendable, Hashable, Identifiable, Codable {
    public let id: UUID
    /// The folder the vault lives in.
    public let root: URL

    public init(id: UUID = UUID(), root: URL) {
        self.id = id
        // Standardised so `/a/./b` and `/a/b` produce identical relative paths later.
        self.root = root.standardizedFileURL
    }

    public var name: String { root.lastPathComponent }

    /// Absolute URL for a vault-relative path.
    public func url(for relativePath: String) -> URL {
        root.appendingPathComponent(relativePath, isDirectory: false)
    }

    /// Vault-relative path for an absolute URL, or `nil` if it falls outside the vault.
    ///
    /// Rejecting outside paths is a containment check, not a tidiness one: a resolved
    /// bookmark or a symlink could otherwise let a write escape the folder the user chose.
    public func relativePath(for url: URL) -> String? {
        let rootPath = root.standardizedFileURL.path
        let filePath = url.standardizedFileURL.path
        let prefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
        guard filePath.hasPrefix(prefix) else { return nil }
        return String(filePath.dropFirst(prefix.count))
    }
}
