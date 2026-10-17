import Foundation

/// A tag and how many notes carry it, including everything beneath it.
///
/// A struct rather than a tuple so it can be used directly in a SwiftUI `ForEach` and
/// compared for equality when the sidebar refreshes.
public struct TagCount: Sendable, Hashable, Identifiable, Codable {
    public let tag: Tag
    public let count: Int

    public var id: String { tag.path }

    public init(tag: Tag, count: Int) {
        self.tag = tag
        self.count = count
    }
}
