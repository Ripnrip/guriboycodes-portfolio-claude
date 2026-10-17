import Foundation

/// What the index remembers about a file so it can tell whether re-parsing is needed.
///
/// Size and modification date are free — they come out of the directory enumeration — and
/// `contentHash` costs a read. The crawler only pays for the hash when the cheap fields
/// disagree, which keeps activation on a large vault from re-reading everything.
public struct FileFingerprint: Sendable, Hashable, Codable {
    public let relativePath: String
    public let size: Int
    public let modifiedAt: Date
    public let contentHash: String

    public init(relativePath: String, size: Int, modifiedAt: Date, contentHash: String) {
        self.relativePath = relativePath
        self.size = size
        self.modifiedAt = modifiedAt
        self.contentHash = contentHash
    }

    /// Whether the cheap metadata matches, meaning the content read can be skipped.
    ///
    /// Modification dates are compared with a tolerance because filesystems and iCloud
    /// disagree about sub-second precision; an exact `==` on `Date` produces spurious
    /// mismatches that would each cost a file read.
    public func metadataMatches(size: Int, modifiedAt: Date) -> Bool {
        self.size == size && abs(self.modifiedAt.timeIntervalSince(modifiedAt)) < 0.001
    }
}
