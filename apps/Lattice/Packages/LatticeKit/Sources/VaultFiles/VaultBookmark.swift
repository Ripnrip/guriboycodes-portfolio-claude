import Foundation

/// Persists the folder the user picked so the vault reopens on next launch.
///
/// A sandboxed app's permission to a user-chosen folder does not survive relaunch — only
/// a security-scoped bookmark carries it across. The bookmark options differ by platform:
/// macOS needs `.withSecurityScope` explicitly, while on iOS the scope travels with a
/// document-picker URL and asking for it is an error.
public enum VaultBookmark {
    /// Bookmark data to store in preferences.
    public static func data(for url: URL) throws -> Data {
        #if os(macOS)
        return try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        #else
        return try url.bookmarkData(
            options: [],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        #endif
    }

    /// Resolves stored bookmark data back to a URL.
    ///
    /// `isStale` means the file moved and the bookmark should be rewritten; the URL is
    /// still usable, so callers should keep going and re-save rather than failing.
    public static func resolve(_ data: Data) throws -> (url: URL, isStale: Bool) {
        var isStale = false
        #if os(macOS)
        let url = try URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        #else
        let url = try URL(
            resolvingBookmarkData: data,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        #endif
        return (url, isStale)
    }

    /// Opens security-scoped access. Must be balanced with ``stopAccessing(_:)``.
    ///
    /// Returns false on platforms with no sandbox scope to claim, where access needs no
    /// claiming in the first place — so a false return is not an error by itself.
    @discardableResult
    public static func startAccessing(_ url: URL) -> Bool {
        #if canImport(Darwin)
        return url.startAccessingSecurityScopedResource()
        #else
        return false
        #endif
    }

    public static func stopAccessing(_ url: URL) {
        #if canImport(Darwin)
        url.stopAccessingSecurityScopedResource()
        #endif
    }
}
