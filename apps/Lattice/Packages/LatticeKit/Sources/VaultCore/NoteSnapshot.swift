import Foundation

/// An immutable, `Sendable` projection of one note.
///
/// This is the only shape note data takes when it crosses an isolation boundary. Realm
/// objects are not `Sendable` and never leave the index actor; everything the UI, the
/// graph engine, and the intents layer see is a snapshot like this one.
public struct NoteSnapshot: Hashable, Sendable, Identifiable, Codable {
    public let id: NoteID
    /// Path relative to the vault root, e.g. `Projects/Lattice.md`.
    public let relativePath: String
    /// Display title: frontmatter `title`, else the first H1, else the filename.
    public let title: String
    public let aliases: [String]
    public let tags: [Tag]
    /// A short plain-text lead-in for list rows and search results.
    public let excerpt: String
    public let wordCount: Int
    public let createdAt: Date
    public let modifiedAt: Date

    public init(
        id: NoteID,
        relativePath: String,
        title: String,
        aliases: [String] = [],
        tags: [Tag] = [],
        excerpt: String = "",
        wordCount: Int = 0,
        createdAt: Date = .distantPast,
        modifiedAt: Date = .distantPast
    ) {
        self.id = id
        self.relativePath = relativePath
        self.title = title
        self.aliases = aliases
        self.tags = tags
        self.excerpt = excerpt
        self.wordCount = wordCount
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    /// Every name this note answers to when resolving `[[links]]`, lowercased.
    public var linkNames: [String] {
        var names = [title.lowercased()]
        names.append(contentsOf: aliases.map { $0.lowercased() })
        // A link may also be written as a path, with or without the extension.
        names.append(relativePath.lowercased())
        if relativePath.hasSuffix(".md") {
            names.append(String(relativePath.dropLast(3)).lowercased())
        }
        return names
    }

    /// The folder this note lives in, or `""` at the vault root.
    public var folder: String {
        guard let slash = relativePath.lastIndex(of: "/") else { return "" }
        return String(relativePath[relativePath.startIndex..<slash])
    }
}
