import Foundation

/// Versioning for the derived index.
///
/// The index holds nothing the Markdown files do not, so it is disposable — and that is
/// what removes Realm migrations from this project entirely. When the schema or the parser
/// changes, bump ``version``; the store is deleted and rebuilt from the files on next
/// open. No migration block, no risk of corrupting user data, because the index was never
/// the user's data.
public enum IndexSchema {
    /// Bump this whenever a record shape changes, or whenever a parser change would
    /// produce different rows from identical files.
    public static let version = 1

    public static let fileName = "lattice-index.realm"

    /// Where the index for a given vault lives.
    ///
    /// Keyed by vault id rather than path so moving a vault folder does not orphan its
    /// index, and two vaults never share one.
    public static func storeURL(forVaultID id: UUID, in directory: URL) -> URL {
        directory
            .appendingPathComponent(id.uuidString, isDirectory: true)
            .appendingPathComponent(fileName, isDirectory: false)
    }
}
