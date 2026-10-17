import Foundation
import MarkdownKit
import RealmSwift
import VaultCore
import VaultFiles

/// What applying a change set did.
public struct IndexStats: Sendable, Equatable {
    public var inserted = 0
    public var updated = 0
    public var refreshed = 0
    public var removed = 0
    public var linkGraphRebuilt = false

    public var isEmpty: Bool {
        inserted == 0 && updated == 0 && refreshed == 0 && removed == 0
    }
}

/// The derived index over a vault's Markdown files.
///
/// Confined to ``VaultIndexActor``, which pins it to one thread for Realm's sake. Every
/// method returns `VaultCore` value types — no Realm object, and nothing non-`Sendable`,
/// ever crosses out of here.
@VaultIndexActor
public final class VaultIndex {
    public let vault: Vault
    private let realm: Realm
    private let parser = NoteParser()

    /// Opens, creating or rebuilding the store as needed.
    ///
    /// Two mechanisms keep the store honest, and both are safe precisely because the index
    /// is derived: `deleteRealmIfMigrationNeeded` handles a changed record shape, and the
    /// stored ``IndexSchema/version`` catches a parser change that would produce different
    /// rows from identical files. Either way the answer is to throw the store away and
    /// re-crawl, never to migrate.
    public init(vault: Vault, directory: URL) throws {
        self.vault = vault

        let storeURL = IndexSchema.storeURL(forVaultID: vault.id, in: directory)
        try FileManager.default.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        var configuration = Realm.Configuration(
            fileURL: storeURL,
            schemaVersion: UInt64(IndexSchema.version),
            deleteRealmIfMigrationNeeded: true
        )
        configuration.objectTypes = [
            NoteRecord.self, LinkRecord.self, BlockRecord.self,
            TagRecord.self, IndexMetaRecord.self,
        ]
        realm = try Realm(configuration: configuration)

        let meta = realm.object(ofType: IndexMetaRecord.self, forPrimaryKey: 0)
        if meta?.schemaVersion != IndexSchema.version {
            try realm.write {
                realm.deleteAll()
                let fresh = IndexMetaRecord()
                fresh.schemaVersion = IndexSchema.version
                fresh.vaultRootPath = vault.root.path
                fresh.lastCrawledAt = .distantPast
                realm.add(fresh, update: .modified)
            }
        }
    }

    // MARK: - Crawl support

    /// Fingerprints of every indexed file, for the crawler's cheap comparison.
    public func knownFingerprints() -> [String: FileFingerprint] {
        var result: [String: FileFingerprint] = [:]
        for record in realm.objects(NoteRecord.self) {
            result[record.relativePath] = FileFingerprint(
                relativePath: record.relativePath,
                size: record.fileSize,
                modifiedAt: record.fileModifiedAt,
                contentHash: record.contentHash
            )
        }
        return result
    }

    /// Writes a change set into the index.
    public func apply(_ changes: VaultChangeSet) throws -> IndexStats {
        var stats = IndexStats()
        guard !changes.isEmpty else { return stats }

        try realm.write {
            for path in changes.removedPaths {
                if let record = noteRecord(forPath: path) {
                    deleteDependents(of: record.id)
                    realm.delete(record)
                    stats.removed += 1
                }
            }

            for file in changes.added {
                upsert(file)
                stats.inserted += 1
            }
            for file in changes.modified {
                upsert(file)
                stats.updated += 1
            }

            // Content identical, only the timestamp moved: refresh the fingerprint so the
            // next crawl is cheap again, and skip the parse entirely.
            for fingerprint in changes.touched {
                if let record = noteRecord(forPath: fingerprint.relativePath) {
                    record.fileSize = fingerprint.size
                    record.fileModifiedAt = fingerprint.modifiedAt
                    record.contentHash = fingerprint.contentHash
                    stats.refreshed += 1
                }
            }

            rebuildTagCounts()

            if changes.invalidatesLinkGraph {
                // Resolution is a whole-vault property: a note added now can resolve a
                // link that has been dangling in a file nobody touched. So any structural
                // change re-resolves everything rather than trying to guess a blast
                // radius that is, in the general case, the entire vault.
                resolveAllLinks()
                stats.linkGraphRebuilt = true
            }

            if let meta = realm.object(ofType: IndexMetaRecord.self, forPrimaryKey: 0) {
                meta.lastCrawledAt = Date()
            }
        }
        return stats
    }

    // MARK: - Writing (must be called inside a write transaction)

    private func upsert(_ file: ScannedFile) {
        let filename = Self.basename(of: file.relativePath)
        let parsed = parser.parse(file.content, filename: filename)

        let id = Self.noteID(for: parsed, relativePath: file.relativePath).rawValue

        // A file whose frontmatter id changed is a different note; drop the stale row that
        // still claims this path, or the vault would show the note twice.
        if let stale = noteRecord(forPath: file.relativePath), stale.id != id {
            deleteDependents(of: stale.id)
            realm.delete(stale)
        }

        let record = realm.object(ofType: NoteRecord.self, forPrimaryKey: id) ?? NoteRecord()
        record.id = id
        record.relativePath = file.relativePath
        record.title = parsed.title
        record.titleLowercased = parsed.title.lowercased()
        record.aliases.removeAll()
        record.aliases.append(objectsIn: parsed.aliases)
        record.tagPaths.removeAll()
        record.tagPaths.append(objectsIn: parsed.tags.map(\.path))
        record.excerpt = parsed.excerpt
        record.wordCount = parsed.wordCount
        record.modifiedAt = file.fingerprint.modifiedAt
        if record.createdAt == Date(timeIntervalSince1970: 0) || record.createdAt == .distantPast {
            record.createdAt = file.fingerprint.modifiedAt
        }
        record.fileSize = file.fingerprint.size
        record.fileModifiedAt = file.fingerprint.modifiedAt
        record.contentHash = file.fingerprint.contentHash
        realm.add(record, update: .modified)

        deleteDependents(of: id)
        for (offset, link) in parsed.links(from: NoteID(rawValue: id)).enumerated() {
            let row = LinkRecord()
            row.id = LinkRecord.identifier(source: id, index: offset)
            row.sourceNoteID = id
            row.targetRaw = link.target
            row.targetNoteID = ""
            row.alias = link.alias
            row.kind = link.kind.rawValue
            row.anchor = Self.encode(link.anchor)
            row.rangeStart = link.range.lowerBound
            row.rangeEnd = link.range.upperBound
            realm.add(row, update: .modified)
        }
        for block in parsed.blockIDs {
            let row = BlockRecord()
            row.id = BlockRecord.identifier(noteID: id, blockID: block.identifier)
            row.noteID = id
            row.blockID = block.identifier
            row.text = Self.substring(of: file.content, utf16Range: block.blockRange)
            realm.add(row, update: .modified)
        }
    }

    private func deleteDependents(of noteID: String) {
        realm.delete(realm.objects(LinkRecord.self).where { $0.sourceNoteID == noteID })
        realm.delete(realm.objects(BlockRecord.self).where { $0.noteID == noteID })
    }

    private func rebuildTagCounts() {
        realm.delete(realm.objects(TagRecord.self))
        var counts: [String: Int] = [:]
        for record in realm.objects(NoteRecord.self) {
            for path in record.tagPaths {
                guard let tag = Tag(path) else { continue }
                counts[tag.path, default: 0] += 1
                // A note tagged `area/work/hiring` also counts toward `area` and
                // `area/work`, so the sidebar's parent rows show subtree totals.
                for ancestor in tag.ancestors {
                    counts[ancestor.path, default: 0] += 1
                }
            }
        }
        for (path, count) in counts {
            let row = TagRecord()
            row.path = path
            row.noteCount = count
            realm.add(row, update: .modified)
        }
    }

    private func resolveAllLinks() {
        let resolver = LinkResolver(notes: snapshots())
        for row in realm.objects(LinkRecord.self) {
            row.targetNoteID = resolver.resolve(row.targetRaw)?.rawValue ?? ""
        }
    }

    // MARK: - Reading

    public func allNotes() -> [NoteSnapshot] {
        snapshots().sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    public func note(id: NoteID) -> NoteSnapshot? {
        realm.object(ofType: NoteRecord.self, forPrimaryKey: id.rawValue).map(Self.snapshot)
    }

    public func note(atPath path: String) -> NoteSnapshot? {
        noteRecord(forPath: path).map(Self.snapshot)
    }

    public func allLinks() -> [LinkSnapshot] {
        realm.objects(LinkRecord.self).map(Self.snapshot)
    }

    /// Notes that link to `id`, with the text around each reference.
    public func backlinks(to id: NoteID) -> [Backlink] {
        let rows = realm.objects(LinkRecord.self).where { $0.targetNoteID == id.rawValue }
        return rows.compactMap { row in
            guard let source = realm.object(ofType: NoteRecord.self, forPrimaryKey: row.sourceNoteID)
            else { return nil }
            return Backlink(source: Self.snapshot(source), link: Self.snapshot(row))
        }
        .sorted { $0.source.title < $1.source.title }
    }

    /// Links whose target does not exist — the notes you have gestured at but not written.
    public func unresolvedLinks() -> [LinkSnapshot] {
        realm.objects(LinkRecord.self).where { $0.targetNoteID == "" }.map(Self.snapshot)
    }

    public func notes(withTag tag: Tag) -> [NoteSnapshot] {
        // Subtree match: `#area` returns notes tagged `#area/work` too.
        snapshots()
            .filter { note in note.tags.contains { $0.isDescendant(of: tag) } }
            .sorted { $0.title < $1.title }
    }

    public func tagCounts() -> [TagCount] {
        realm.objects(TagRecord.self)
            .compactMap { row in Tag(row.path).map { TagCount(tag: $0, count: row.noteCount) } }
            .sorted { $0.tag < $1.tag }
    }

    /// Substring search over title, aliases, and excerpt.
    ///
    /// Realm has no FTS5 equivalent, so this is a `CONTAINS` scan rather than a real
    /// full-text query — adequate for a link picker over a personal vault, and explicitly
    /// not a substitute for the inverted index unlinked-mention search will need.
    public func search(_ query: String, limit: Int = 50) -> [NoteSnapshot] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return Array(allNotes().prefix(limit)) }
        let needle = trimmed.lowercased()

        return snapshots()
            .filter { note in
                note.title.lowercased().contains(needle)
                    || note.aliases.contains { $0.lowercased().contains(needle) }
                    || note.excerpt.lowercased().contains(needle)
                    || note.relativePath.lowercased().contains(needle)
            }
            // Prefix matches on the title first; that is what a link picker wants.
            .sorted { lhs, rhs in
                let left = lhs.title.lowercased().hasPrefix(needle)
                let right = rhs.title.lowercased().hasPrefix(needle)
                if left != right { return left }
                return lhs.title < rhs.title
            }
            .prefix(limit)
            .map { $0 }
    }

    /// The graph the Metal engine renders.
    public func graph(includeDangling: Bool = true) -> GraphSnapshot {
        let notes = snapshots()
        // Colour by top-level tag, so clusters in the graph line up with how the vault is
        // actually organised rather than with an arbitrary index.
        let groups = Dictionary(
            uniqueKeysWithValues: Set(notes.compactMap { $0.tags.first?.components.first })
                .sorted()
                .enumerated()
                .map { ($0.element, $0.offset) }
        )
        return LinkResolver.buildGraph(
            notes: notes,
            links: allLinks(),
            includeDangling: includeDangling,
            group: { note in
                note.tags.first?.components.first.flatMap { groups[$0] } ?? 0
            }
        )
    }

    public func noteCount() -> Int { realm.objects(NoteRecord.self).count }

    // MARK: - Conversions

    private func snapshots() -> [NoteSnapshot] {
        realm.objects(NoteRecord.self).map(Self.snapshot)
    }

    private func noteRecord(forPath path: String) -> NoteRecord? {
        realm.objects(NoteRecord.self).where { $0.relativePath == path }.first
    }

    private static func snapshot(_ record: NoteRecord) -> NoteSnapshot {
        NoteSnapshot(
            id: NoteID(rawValue: record.id),
            relativePath: record.relativePath,
            title: record.title,
            aliases: Array(record.aliases),
            tags: record.tagPaths.compactMap { Tag($0) },
            excerpt: record.excerpt,
            wordCount: record.wordCount,
            createdAt: record.createdAt,
            modifiedAt: record.modifiedAt
        )
    }

    private static func snapshot(_ record: LinkRecord) -> LinkSnapshot {
        LinkSnapshot(
            source: NoteID(rawValue: record.sourceNoteID),
            target: record.targetRaw,
            anchor: decode(record.anchor),
            alias: record.alias,
            kind: LinkKind(rawValue: record.kind) ?? .wikilink,
            range: record.rangeStart..<max(record.rangeStart, record.rangeEnd)
        )
    }

    /// Identity: frontmatter `id` when present, else derived from the path.
    ///
    /// The derived form means a plain Obsidian vault works with no metadata at all, at the
    /// cost that moving such a file reads as a delete plus an add.
    static func noteID(for parsed: ParsedNote, relativePath: String) -> NoteID {
        if let id = parsed.frontmatter.id {
            return NoteID(rawValue: id)
        }
        return NoteID.derived(fromRelativePath: relativePath)
    }

    private static func encode(_ anchor: LinkAnchor) -> String {
        switch anchor {
        case .wholeNote: return ""
        case .heading(let heading): return "#" + heading
        case .block(let identifier): return "^" + identifier
        }
    }

    private static func decode(_ raw: String) -> LinkAnchor {
        if raw.hasPrefix("^") { return .block(String(raw.dropFirst())) }
        if raw.hasPrefix("#") { return .heading(String(raw.dropFirst())) }
        return .wholeNote
    }

    /// Filename without directory or note extension — the parser's last-resort title.
    static func basename(of relativePath: String) -> String {
        var name = relativePath
        if let slash = name.lastIndex(of: "/") {
            name = String(name[name.index(after: slash)...])
        }
        for suffix in [".markdown", ".md"] where name.hasSuffix(suffix) {
            name = String(name.dropLast(suffix.count))
            break
        }
        return name
    }

    private static func substring(of source: String, utf16Range: Range<Int>) -> String {
        let units = Array(source.utf16)
        let lower = max(0, min(utf16Range.lowerBound, units.count))
        let upper = max(lower, min(utf16Range.upperBound, units.count))
        return String(decoding: units[lower..<upper], as: UTF16.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// A reference to a note, together with the note doing the referencing.
public struct Backlink: Sendable, Hashable, Identifiable {
    public let source: NoteSnapshot
    public let link: LinkSnapshot

    public var id: String { "\(source.id.rawValue)#\(link.range.lowerBound)" }

    public init(source: NoteSnapshot, link: LinkSnapshot) {
        self.source = source
        self.link = link
    }
}
