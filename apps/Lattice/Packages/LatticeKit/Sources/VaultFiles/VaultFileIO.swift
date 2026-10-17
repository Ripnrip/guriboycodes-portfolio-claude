import Foundation

/// Reads and writes vault files.
///
/// On Apple platforms every access goes through `NSFileCoordinator`, which is what lets
/// Lattice and Obsidian (and iCloud's own sync daemon) hold the same vault open without
/// tearing each other's writes. `NSFileCoordinator` does not exist in corelibs-Foundation,
/// so on Linux the same calls fall through to direct IO — enough for the unit tests, and
/// never the shipping path.
public struct VaultFileIO: Sendable {
    public init() {}

    public func read(_ url: URL) throws -> String {
        try coordinatedRead(url) {
            let data = try Data(contentsOf: $0)
            // Vault files are Markdown; fall back to Latin-1 rather than failing outright,
            // because a stray non-UTF-8 note should not break a whole crawl.
            return String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1)
                ?? ""
        }
    }

    public func write(_ text: String, to url: URL) throws {
        try coordinatedWrite(url) { target in
            try FileManager.default.createDirectory(
                at: target.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            // Atomic so a crash mid-write cannot truncate a note.
            try Data(text.utf8).write(to: target, options: .atomic)
        }
    }

    public func move(from source: URL, to destination: URL) throws {
        try coordinatedMove(source, destination) { from, to in
            try FileManager.default.createDirectory(
                at: to.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try FileManager.default.moveItem(at: from, to: to)
        }
    }

    public func delete(_ url: URL) throws {
        try coordinatedWrite(url) {
            try FileManager.default.removeItem(at: $0)
        }
    }

    public func metadata(of url: URL) throws -> (size: Int, modifiedAt: Date) {
        let values = try url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        return (values.fileSize ?? 0, values.contentModificationDate ?? .distantPast)
    }

    // MARK: - Coordination

    #if canImport(Darwin)
    private func coordinatedRead<T>(_ url: URL, _ body: (URL) throws -> T) throws -> T {
        let coordinator = NSFileCoordinator()
        var coordinationError: NSError?
        var result: Result<T, Error>?
        coordinator.coordinate(readingItemAt: url, options: [], error: &coordinationError) {
            result = Result { try body($0) }
        }
        if let coordinationError { throw coordinationError }
        guard let result else { throw VaultFileError.coordinationFailed(url) }
        return try result.get()
    }

    private func coordinatedWrite(_ url: URL, _ body: (URL) throws -> Void) throws {
        let coordinator = NSFileCoordinator()
        var coordinationError: NSError?
        var thrown: Error?
        coordinator.coordinate(writingItemAt: url, options: [], error: &coordinationError) {
            do { try body($0) } catch { thrown = error }
        }
        if let coordinationError { throw coordinationError }
        if let thrown { throw thrown }
    }

    private func coordinatedMove(
        _ source: URL,
        _ destination: URL,
        _ body: (URL, URL) throws -> Void
    ) throws {
        let coordinator = NSFileCoordinator()
        var coordinationError: NSError?
        var thrown: Error?
        coordinator.coordinate(
            writingItemAt: source,
            options: .forMoving,
            writingItemAt: destination,
            options: .forReplacing,
            error: &coordinationError
        ) { from, to in
            do { try body(from, to) } catch { thrown = error }
        }
        if let coordinationError { throw coordinationError }
        if let thrown { throw thrown }
    }
    #else
    private func coordinatedRead<T>(_ url: URL, _ body: (URL) throws -> T) throws -> T {
        try body(url)
    }

    private func coordinatedWrite(_ url: URL, _ body: (URL) throws -> Void) throws {
        try body(url)
    }

    private func coordinatedMove(
        _ source: URL,
        _ destination: URL,
        _ body: (URL, URL) throws -> Void
    ) throws {
        try body(source, destination)
    }
    #endif
}

public enum VaultFileError: Error, LocalizedError {
    case coordinationFailed(URL)
    case outsideVault(URL)

    public var errorDescription: String? {
        switch self {
        case .coordinationFailed(let url):
            return "Could not coordinate access to \(url.lastPathComponent)."
        case .outsideVault(let url):
            return "\(url.lastPathComponent) is outside the vault folder."
        }
    }
}
