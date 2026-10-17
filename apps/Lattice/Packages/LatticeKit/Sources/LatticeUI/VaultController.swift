import Foundation
import GraphEngine
import MarkdownKit
import Observation
import SwiftUI
import VaultCore
import VaultFiles
import VaultIndex

/// The app's single point of contact with the vault.
///
/// Lives on the main actor and holds only `Sendable` snapshots. The index lives on
/// ``VaultIndexActor`` and is reached with `await`; no Realm object is ever stored here,
/// which is what keeps the UI layer free of Realm's thread-confinement rules.
@MainActor
@Observable
public final class VaultController {
    public enum State: Equatable {
        case noVault
        case opening
        case ready
        case failed(String)
    }

    public private(set) var state: State = .noVault
    public private(set) var vault: Vault?
    public private(set) var notes: [NoteSnapshot] = []
    public private(set) var tags: [TagCount] = []
    public private(set) var unresolvedTargets: [String] = []
    public private(set) var backlinks: [Backlink] = []
    public private(set) var isIndexing = false
    /// Set when live file watching is unavailable, so the UI can be honest about it.
    public private(set) var usesPollingOnly = !VaultWatcher.isSupported

    public private(set) var selectedNote: NoteSnapshot?
    /// Body text of the selected note, as loaded from disk.
    public private(set) var editorText: String = ""

    public let graphModel = GraphViewModel()

    private let io = VaultFileIO()
    private let crawler: VaultCrawler
    private let indexDirectory: URL
    private var index: VaultIndex?
    private var watcher: VaultWatcher?
    private var refreshTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?

    public init(indexDirectory: URL? = nil) {
        self.crawler = VaultCrawler(io: io)
        self.indexDirectory = indexDirectory ?? Self.defaultIndexDirectory()
        graphModel.onOpenNote = { [weak self] id in
            self?.selectNote(id: id)
        }
    }

    private static func defaultIndexDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("Lattice/Index", isDirectory: true)
    }

    // MARK: - Opening

    private static let bookmarkKey = "codes.guriboy.lattice.vaultBookmark"

    /// Reopens the vault from the last session, if there was one.
    ///
    /// Returns false when there is nothing stored or the bookmark no longer resolves — the
    /// folder was deleted, or the user revoked access — in which case the app should ask
    /// for a folder rather than reporting an error for something routine.
    @discardableResult
    public func restoreLastVault() async -> Bool {
        guard let data = UserDefaults.standard.data(forKey: Self.bookmarkKey) else {
            return false
        }
        do {
            let resolved = try VaultBookmark.resolve(data)
            await open(resolved.url)
            // A stale bookmark still works, but only once; rewrite it while we can.
            if resolved.isStale, case .ready = state,
               let refreshed = try? VaultBookmark.data(for: resolved.url) {
                UserDefaults.standard.set(refreshed, forKey: Self.bookmarkKey)
            }
            if case .ready = state { return true }
            return false
        } catch {
            UserDefaults.standard.removeObject(forKey: Self.bookmarkKey)
            return false
        }
    }

    /// Opens a vault folder and indexes it.
    public func open(_ url: URL) async {
        state = .opening
        stopWatching()
        if let previous = vault?.root {
            VaultBookmark.stopAccessing(previous)
        }

        let vault = Vault(root: url)
        self.vault = vault
        VaultBookmark.startAccessing(url)

        do {
            let index = try await VaultIndex(vault: vault, directory: indexDirectory)
            self.index = index
            await refresh()
            // `refresh` reports its own failures, and overwriting them with `.ready` here
            // would hide a vault that indexed badly behind a UI that looks fine.
            if case .failed = state { return }

            startWatching(vault)
            state = .ready
            // Only persist a vault that actually opened, so a failed pick does not become
            // the folder we try again on next launch.
            if let bookmark = try? VaultBookmark.data(for: url) {
                UserDefaults.standard.set(bookmark, forKey: Self.bookmarkKey)
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Re-crawls the vault and applies whatever changed.
    public func refresh() async {
        guard let vault, let index else { return }
        isIndexing = true
        defer { isIndexing = false }

        do {
            let known = await index.knownFingerprints()
            // The crawl touches the filesystem, so keep it off the main actor.
            let crawler = self.crawler
            let changes = try await Task.detached(priority: .userInitiated) {
                try crawler.scan(vault, known: known)
            }.value

            let stats = try await index.apply(changes)
            notes = await index.allNotes()
            tags = await index.tagCounts()
            unresolvedTargets = await Self.distinctTargets(of: index.unresolvedLinks())

            // Only rebuild the graph when the structure actually moved; a metadata-only
            // crawl would otherwise reset the layout for no visible reason.
            if stats.linkGraphRebuilt || graphModel.snapshot.isEmpty {
                graphModel.load(await index.graph())
            }
            if let selected = selectedNote {
                await refreshSelection(selected.id)
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private static func distinctTargets(of links: [LinkSnapshot]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for link in links {
            let key = LinkResolver.normalize(link.target)
            guard !key.isEmpty, seen.insert(key).inserted else { continue }
            result.append(link.target)
        }
        return result.sorted()
    }

    /// Clears a failure so the UI can dismiss its alert.
    ///
    /// The state machine needs an explicit way back out of `.failed`; without it the alert
    /// binding has nothing to write to and the alert re-presents forever.
    public func clearFailure() {
        guard case .failed = state else { return }
        state = vault == nil ? .noVault : .ready
    }

    // MARK: - Watching

    private func startWatching(_ vault: Vault) {
        guard VaultWatcher.isSupported else { return }
        let watcher = VaultWatcher(vault: vault) { [weak self] in
            // FSEvents calls back on its own queue; hop to the main actor and coalesce,
            // because a burst of saves should produce one re-crawl.
            Task { @MainActor [weak self] in
                self?.scheduleRefresh()
            }
        }
        watcher.start()
        self.watcher = watcher
    }

    private func stopWatching() {
        watcher?.stop()
        watcher = nil
        refreshTask?.cancel()
        refreshTask = nil
    }

    private func scheduleRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            await self?.refresh()
        }
    }

    /// Call when the app becomes active.
    ///
    /// On iOS this is the only thing keeping the index current, because there is no
    /// reliable recursive file watcher; on macOS it covers changes made while the app was
    /// backgrounded and FSEvents was not running.
    public func applicationBecameActive() {
        scheduleRefresh()
    }

    // MARK: - Selection and editing

    public func select(_ note: NoteSnapshot?) {
        selectedNote = note
        guard let note else {
            editorText = ""
            backlinks = []
            return
        }
        Task { await refreshSelection(note.id) }
    }

    public func selectNote(id: NoteID) {
        if let note = notes.first(where: { $0.id == id }) {
            select(note)
        }
    }

    private func refreshSelection(_ id: NoteID) async {
        guard let index, let vault else { return }
        guard let note = await index.note(id: id) else {
            selectedNote = nil
            editorText = ""
            backlinks = []
            return
        }
        selectedNote = note
        backlinks = await index.backlinks(to: id)
        editorText = (try? io.read(vault.url(for: note.relativePath))) ?? ""
    }

    /// Records an edit and saves it after a pause.
    ///
    /// Debounced rather than saved per keystroke: each write is a coordinated, atomic file
    /// replacement that other apps watching the vault will see, and emitting one per
    /// character would make Obsidian's own indexer thrash.
    public func updateEditorText(_ text: String) {
        editorText = text
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            await self?.saveSelectedNote()
        }
    }

    public func saveSelectedNote() async {
        guard let vault, let note = selectedNote else { return }
        do {
            try io.write(editorText, to: vault.url(for: note.relativePath))
            // On iOS nothing will tell us the file changed, so re-crawl explicitly.
            if !VaultWatcher.isSupported { scheduleRefresh() }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: - Creating and renaming

    /// Creates a note, optionally seeding it from a link that had nowhere to point.
    @discardableResult
    public func createNote(titled title: String, inFolder folder: String = "") async -> NoteSnapshot? {
        guard let vault else { return nil }
        let safeTitle = Self.sanitize(title)
        guard !safeTitle.isEmpty else { return nil }

        let relativePath = folder.isEmpty
            ? "\(safeTitle).md"
            : "\(folder)/\(safeTitle).md"
        let target = vault.url(for: relativePath)
        guard !FileManager.default.fileExists(atPath: target.path) else {
            // Already there — open it rather than clobbering a note with the same name.
            await refresh()
            return notes.first { $0.relativePath == relativePath }
        }

        // A stamped id makes the note's identity survive being moved later.
        let body = """
            ---
            id: \(NoteID.generate().rawValue)
            title: \(safeTitle)
            created: \(Self.dateFormatter.string(from: Date()))
            ---

            # \(safeTitle)

            """
        do {
            try io.write(body, to: target)
            await refresh()
            return notes.first { $0.relativePath == relativePath }
        } catch {
            state = .failed(error.localizedDescription)
            return nil
        }
    }

    /// Renames a note and repairs every link that pointed at it.
    ///
    /// The repair is part of the rename, not a follow-up: renaming without it silently
    /// breaks every reference, and the broken links would not be visible until someone
    /// clicked one.
    public func rename(_ note: NoteSnapshot, to newTitle: String) async {
        guard let vault, let index else { return }
        let safeTitle = Self.sanitize(newTitle)
        guard !safeTitle.isEmpty, safeTitle != note.title else { return }

        let folder = note.folder
        let newPath = folder.isEmpty ? "\(safeTitle).md" : "\(folder)/\(safeTitle).md"
        let oldForms = LinkRewriter.targetForms(
            relativePath: note.relativePath,
            title: note.title,
            aliases: note.aliases
        )
        let newTarget = folder.isEmpty ? safeTitle : "\(folder)/\(safeTitle)"

        do {
            try io.move(from: vault.url(for: note.relativePath), to: vault.url(for: newPath))

            // Repair references in every note that links here.
            for backlink in await index.backlinks(to: note.id) {
                let url = vault.url(for: backlink.source.relativePath)
                guard let text = try? io.read(url),
                      let rewritten = LinkRewriter.rewriting(
                          text, matching: oldForms, to: newTarget
                      )
                else { continue }
                try io.write(rewritten, to: url)
            }

            await refresh()
            // A note with no frontmatter id is identified by its path, so the move just
            // changed its id; re-select by the new path rather than the stale id.
            select(notes.first { $0.relativePath == newPath })
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    public func deleteNote(_ note: NoteSnapshot) async {
        guard let vault else { return }
        do {
            try io.delete(vault.url(for: note.relativePath))
            if selectedNote?.id == note.id { select(nil) }
            await refresh()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: - Link picker support

    /// Notes matching `query`, for `[[` autocomplete and the link picker.
    public func suggestions(for query: String, limit: Int = 12) async -> [NoteSnapshot] {
        guard let index else { return [] }
        return await index.search(query, limit: limit)
    }

    public func notes(withTag tag: Tag) async -> [NoteSnapshot] {
        guard let index else { return [] }
        return await index.notes(withTag: tag)
    }

    // MARK: - Helpers

    /// Strips what a filename cannot contain, so a title is safe to use as a path.
    static func sanitize(_ title: String) -> String {
        let forbidden = CharacterSet(charactersIn: "/\\:*?\"<>|")
        return title
            .components(separatedBy: forbidden)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
