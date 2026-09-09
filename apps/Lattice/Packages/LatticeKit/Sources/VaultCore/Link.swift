import Foundation

/// How one note came to reference another.
public enum LinkKind: String, Hashable, Sendable, Codable {
    /// `[[Note]]` — an ordinary wiki link.
    case wikilink
    /// `![[Note]]` — a transclusion; the target's content renders inline.
    case embed
    /// A CommonMark `[text](path.md)` link pointing inside the vault.
    case markdown
}

/// The part of a note a link points at.
public enum LinkAnchor: Hashable, Sendable, Codable {
    case wholeNote
    /// `[[Note#Heading]]`
    case heading(String)
    /// `[[Note#^block-id]]`
    case block(String)
}

/// A reference from one note to another, as written.
///
/// `target` is the *unresolved* text exactly as the author typed it. Resolution to a
/// ``NoteID`` happens in the index, because it depends on the whole vault (titles,
/// aliases, and paths all participate). An unresolved link is not an error — it is how
/// you create a note by linking to it first.
public struct LinkSnapshot: Hashable, Sendable, Codable {
    public let source: NoteID
    public let target: String
    public let anchor: LinkAnchor
    public let alias: String?
    public let kind: LinkKind
    /// UTF-16 offsets into the note body, suitable for TextKit.
    public let range: Range<Int>

    public init(
        source: NoteID,
        target: String,
        anchor: LinkAnchor = .wholeNote,
        alias: String? = nil,
        kind: LinkKind,
        range: Range<Int>
    ) {
        self.source = source
        self.target = target
        self.anchor = anchor
        self.alias = alias
        self.kind = kind
        self.range = range
    }

    /// The text a reader should see for this link.
    public var displayText: String { alias ?? target }
}

/// A link whose target resolved to a note that exists.
public struct ResolvedLink: Hashable, Sendable {
    public let link: LinkSnapshot
    public let target: NoteID

    public init(link: LinkSnapshot, target: NoteID) {
        self.link = link
        self.target = target
    }
}
