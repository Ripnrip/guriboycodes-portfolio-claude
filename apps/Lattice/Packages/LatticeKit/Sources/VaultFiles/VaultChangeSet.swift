import Foundation

/// A file the crawler looked at, with its content attached only when it had to be read.
///
/// Carrying the content avoids reading a changed file twice — once to hash it, once to
/// parse it — without holding the whole vault in memory, because unchanged files never
/// get read at all.
public struct ScannedFile: Sendable, Equatable {
    public let fingerprint: FileFingerprint
    public let content: String

    public init(fingerprint: FileFingerprint, content: String) {
        self.fingerprint = fingerprint
        self.content = content
    }

    public var relativePath: String { fingerprint.relativePath }
}

/// What changed in the vault since the index last looked.
public struct VaultChangeSet: Sendable, Equatable {
    /// Files the index has never seen. Need parsing.
    public var added: [ScannedFile] = []
    /// Files whose content genuinely changed. Need re-parsing.
    public var modified: [ScannedFile] = []
    /// Files whose size or timestamp moved but whose bytes are identical.
    ///
    /// This is the iCloud case, and it is the whole reason the content hash exists: the
    /// sync daemon rewrites modification dates on files it has merely re-downloaded. The
    /// index needs its stored fingerprint refreshed so the next crawl is cheap again, but
    /// re-parsing would be pure waste.
    public var touched: [FileFingerprint] = []
    /// Files that matched on cheap metadata and were never opened.
    public var unchangedPaths: [String] = []
    /// Paths the index knows that are no longer on disk.
    public var removedPaths: [String] = []

    public init() {}

    /// Whether anything needs writing to the index.
    public var isEmpty: Bool {
        added.isEmpty && modified.isEmpty && touched.isEmpty && removedPaths.isEmpty
    }

    /// Files whose text must be re-parsed.
    public var needingParse: [ScannedFile] { added + modified }

    /// Every path the crawl saw on disk.
    public var seenPaths: [String] {
        added.map(\.relativePath)
            + modified.map(\.relativePath)
            + touched.map(\.relativePath)
            + unchangedPaths
    }

    /// True when the link graph has to be rebuilt.
    ///
    /// Resolution is a whole-vault concern — a new note can resolve a link that was
    /// dangling in a file nothing touched — so any structural change invalidates it,
    /// while a `touched`-only crawl does not.
    public var invalidatesLinkGraph: Bool {
        !added.isEmpty || !modified.isEmpty || !removedPaths.isEmpty
    }
}
