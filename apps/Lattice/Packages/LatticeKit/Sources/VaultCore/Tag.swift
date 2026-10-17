import Foundation

/// A hierarchical tag such as `#area/work/hiring`.
///
/// Tags compare and sort by their component path, so `area/work` sorts adjacent to
/// `area/work/hiring` and a prefix test is a cheap way to gather a subtree.
public struct Tag: Hashable, Sendable, Comparable, Codable, CustomStringConvertible {
    /// Path components, already lowercased and stripped of the leading `#`.
    public let components: [String]

    public init?(_ raw: String) {
        var text = raw
        if text.hasPrefix("#") { text.removeFirst() }
        let parts = text.split(separator: "/", omittingEmptySubsequences: true).map {
            $0.lowercased()
        }
        guard !parts.isEmpty else { return nil }
        self.components = parts
    }

    public init?(components: [String]) {
        guard !components.isEmpty else { return nil }
        self.components = components.map { $0.lowercased() }
    }

    /// The tag without a leading `#`, e.g. `area/work/hiring`.
    public var path: String { components.joined(separator: "/") }

    /// The tag as it appears in note text, e.g. `#area/work/hiring`.
    public var display: String { "#" + path }

    /// The last path component, e.g. `hiring`.
    public var leaf: String { components[components.count - 1] }

    /// The immediate parent tag, or `nil` for a top-level tag.
    public var parent: Tag? {
        guard components.count > 1 else { return nil }
        return Tag(components: Array(components.dropLast()))
    }

    /// Every ancestor of this tag, nearest first, excluding the tag itself.
    public var ancestors: [Tag] {
        var result: [Tag] = []
        var current = parent
        while let tag = current {
            result.append(tag)
            current = tag.parent
        }
        return result
    }

    /// Whether `self` is `other` or lives beneath it.
    public func isDescendant(of other: Tag) -> Bool {
        guard components.count >= other.components.count else { return false }
        return Array(components.prefix(other.components.count)) == other.components
    }

    public static func < (lhs: Tag, rhs: Tag) -> Bool {
        // Lexicographic over components so parents sort immediately before their children.
        for (l, r) in zip(lhs.components, rhs.components) where l != r {
            return l < r
        }
        return lhs.components.count < rhs.components.count
    }

    public var description: String { display }
}
