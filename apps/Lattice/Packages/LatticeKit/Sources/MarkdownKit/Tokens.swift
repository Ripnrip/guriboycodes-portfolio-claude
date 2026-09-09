import Foundation
import VaultCore

/// A `[[wikilink]]` or `![[embed]]` found in note text.
public struct WikilinkToken: Hashable, Sendable {
    /// The note name as written, e.g. `Projects/Lattice`.
    public let target: String
    public let anchor: LinkAnchor
    public let alias: String?
    public let isEmbed: Bool
    /// UTF-16 offsets of the whole token, including brackets and any leading `!`.
    public let range: Range<Int>

    public init(
        target: String,
        anchor: LinkAnchor = .wholeNote,
        alias: String? = nil,
        isEmbed: Bool = false,
        range: Range<Int>
    ) {
        self.target = target
        self.anchor = anchor
        self.alias = alias
        self.isEmbed = isEmbed
        self.range = range
    }

    public var kind: LinkKind { isEmbed ? .embed : .wikilink }
}

/// A `#tag` or `#nested/tag` found in note text.
public struct TagToken: Hashable, Sendable {
    public let tag: Tag
    public let range: Range<Int>

    public init(tag: Tag, range: Range<Int>) {
        self.tag = tag
        self.range = range
    }
}

/// A `^block-id` anchor at the end of a line.
public struct BlockIDToken: Hashable, Sendable {
    public let identifier: String
    public let range: Range<Int>
    /// UTF-16 range of the line the anchor terminates, excluding the anchor itself.
    public let blockRange: Range<Int>

    public init(identifier: String, range: Range<Int>, blockRange: Range<Int>) {
        self.identifier = identifier
        self.range = range
        self.blockRange = blockRange
    }
}

/// An ATX heading (`## Like this`).
public struct HeadingToken: Hashable, Sendable {
    public let level: Int
    public let text: String
    public let range: Range<Int>

    public init(level: Int, text: String, range: Range<Int>) {
        self.level = level
        self.text = text
        self.range = range
    }
}
