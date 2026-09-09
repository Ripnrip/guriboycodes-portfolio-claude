import Foundation

/// Stable identity for a note.
///
/// The identifier is persisted in a note's YAML frontmatter (`id:`). When a file has no
/// `id`, the vault derives one from its path so that a freshly-opened Obsidian vault is
/// usable immediately; the derived form is marked so callers can offer to stamp a durable
/// id into the file.
public struct NoteID: Hashable, Sendable, Codable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// A fresh, durable identifier suitable for writing into frontmatter.
    public static func generate() -> NoteID {
        NoteID(rawValue: UUID().uuidString.lowercased())
    }

    /// Deterministic identity for a note that has no `id` in its frontmatter.
    ///
    /// Derived ids are stable for as long as the file stays put; moving the file changes
    /// the id, which is exactly why stamping a real id is preferable.
    public static func derived(fromRelativePath path: String) -> NoteID {
        NoteID(rawValue: "path:" + path.lowercased())
    }

    /// Whether this id came from ``derived(fromRelativePath:)`` rather than frontmatter.
    public var isDerived: Bool { rawValue.hasPrefix("path:") }

    public var description: String { rawValue }
}
