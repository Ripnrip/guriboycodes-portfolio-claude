import Foundation
import RealmSwift

/// Index row for one note.
///
/// Every field here is derived from the file on disk. Nothing the user typed exists only
/// in Realm, which is what makes the whole store safe to delete and rebuild.
final class NoteRecord: Object, Identifiable {
    @Persisted(primaryKey: true) var id: String
    @Persisted(indexed: true) var relativePath: String
    @Persisted(indexed: true) var titleLowercased: String
    @Persisted var title: String
    @Persisted var aliases: List<String>
    @Persisted var tagPaths: List<String>
    @Persisted var excerpt: String
    @Persisted var wordCount: Int
    @Persisted var createdAt: Date
    @Persisted var modifiedAt: Date

    // Fingerprint, so the next crawl can skip this file without reading it.
    @Persisted var fileSize: Int
    @Persisted var fileModifiedAt: Date
    @Persisted var contentHash: String
}

/// Index row for one `[[link]]`.
///
/// `targetNoteID` is empty when the link dangles. That is a normal state, not an error —
/// linking to a note before writing it is how people work — and those rows are what the
/// graph draws as hollow placeholder nodes.
final class LinkRecord: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted(indexed: true) var sourceNoteID: String
    @Persisted(indexed: true) var targetNoteID: String
    @Persisted var targetRaw: String
    @Persisted var alias: String?
    /// Raw value of `LinkKind`.
    @Persisted var kind: String
    /// `""` whole note, `"#heading"`, or `"^block"`.
    @Persisted var anchor: String
    @Persisted var rangeStart: Int
    @Persisted var rangeEnd: Int

    /// Deterministic id so re-indexing a file replaces its rows instead of duplicating.
    static func identifier(source: String, index: Int) -> String {
        "\(source)#\(index)"
    }
}

/// A `^block-id` anchor, so `[[Note#^id]]` can resolve to a span of text.
final class BlockRecord: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted(indexed: true) var noteID: String
    @Persisted var blockID: String
    @Persisted var text: String

    static func identifier(noteID: String, blockID: String) -> String {
        "\(noteID)#^\(blockID)"
    }
}

/// A tag and how many notes carry it, for the sidebar.
final class TagRecord: Object {
    @Persisted(primaryKey: true) var path: String
    @Persisted var noteCount: Int
}

/// One row, holding the schema version the store was built with.
final class IndexMetaRecord: Object {
    @Persisted(primaryKey: true) var id: Int = 0
    @Persisted var schemaVersion: Int
    @Persisted var vaultRootPath: String
    @Persisted var lastCrawledAt: Date
}
