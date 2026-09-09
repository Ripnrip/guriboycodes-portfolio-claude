import Foundation
import VaultCore

/// Resolves the text inside `[[brackets]]` to a note in the vault.
///
/// Obsidian-compatible precedence, most specific first:
/// 1. exact relative path (`Projects/Lattice.md`, with or without the extension)
/// 2. exact title
/// 3. exact alias
/// 4. unique case-insensitive basename match
///
/// A link that matches nothing is *not* an error. Linking to a note before creating it is
/// the normal way to write, so unresolved links are first-class: they appear in the graph
/// as hollow nodes and in the UI as "create this note".
public struct LinkResolver: Sendable {
    private var byPath: [String: NoteID] = [:]
    private var byTitle: [String: NoteID] = [:]
    private var byAlias: [String: NoteID] = [:]
    /// Basename → every note sharing it. Ambiguous names stay unresolved on purpose.
    private var byBasename: [String: [NoteID]] = [:]

    public init(notes: [NoteSnapshot]) {
        for note in notes {
            let path = note.relativePath.lowercased()
            byPath[path] = note.id
            if path.hasSuffix(".md") {
                byPath[String(path.dropLast(3))] = note.id
            }
            // First writer wins so a rebuild is deterministic rather than dictionary-ordered.
            let title = note.title.lowercased()
            if byTitle[title] == nil { byTitle[title] = note.id }
            for alias in note.aliases {
                let key = alias.lowercased()
                if byAlias[key] == nil { byAlias[key] = note.id }
            }
            byBasename[Self.basename(of: path), default: []].append(note.id)
        }
    }

    /// The note a link target names, or `nil` when the link dangles.
    public func resolve(_ target: String) -> NoteID? {
        let key = Self.normalize(target)
        guard !key.isEmpty else { return nil }

        if let id = byPath[key] { return id }
        if let id = byPath[key + ".md"] { return id }
        if let id = byTitle[key] { return id }
        if let id = byAlias[key] { return id }

        // Only accept a basename match when it is unambiguous.
        if let candidates = byBasename[key], candidates.count == 1 {
            return candidates[0]
        }
        return nil
    }

    /// Resolves every link in `links`, partitioning into resolved and dangling.
    public func resolveAll(
        _ links: [LinkSnapshot]
    ) -> (resolved: [ResolvedLink], dangling: [LinkSnapshot]) {
        var resolved: [ResolvedLink] = []
        var dangling: [LinkSnapshot] = []
        for link in links {
            if let target = resolve(link.target) {
                resolved.append(ResolvedLink(link: link, target: target))
            } else {
                dangling.append(link)
            }
        }
        return (resolved, dangling)
    }

    /// Builds the graph the Metal engine renders.
    ///
    /// Parallel links between the same pair collapse into one edge whose weight is the
    /// number of references, so a note you cite five times pulls harder than one you cite
    /// once. Dangling links become hollow placeholder nodes, which is what makes the
    /// graph show you the shape of what you have not written yet.
    public static func buildGraph(
        notes: [NoteSnapshot],
        links: [LinkSnapshot],
        includeDangling: Bool = true,
        group: (NoteSnapshot) -> Int = { _ in 0 }
    ) -> GraphSnapshot {
        let resolver = LinkResolver(notes: notes)

        var rawNodes: [(id: NoteID, label: String, group: Int)] = notes.map {
            (id: $0.id, label: $0.title, group: group($0))
        }
        var indexByID: [NoteID: Int] = [:]
        for (offset, note) in notes.enumerated() { indexByID[note.id] = offset }

        var weights: [EdgeKey: Float] = [:]
        var placeholderIndex: [String: Int] = [:]

        for link in links {
            guard let sourceIndex = indexByID[link.source] else { continue }

            let targetIndex: Int
            if let resolvedID = resolver.resolve(link.target), let index = indexByID[resolvedID] {
                targetIndex = index
            } else if includeDangling {
                let key = Self.normalize(link.target)
                guard !key.isEmpty else { continue }
                if let existing = placeholderIndex[key] {
                    targetIndex = existing
                } else {
                    let index = rawNodes.count
                    rawNodes.append(
                        (id: NoteID(rawValue: "unresolved:" + key), label: link.target, group: -1)
                    )
                    placeholderIndex[key] = index
                    targetIndex = index
                }
            } else {
                continue
            }

            guard sourceIndex != targetIndex else { continue }
            weights[EdgeKey(sourceIndex, targetIndex), default: 0] += 1
        }

        // Sorted for determinism; the GPU does not care but tests and diffs do.
        let edges = weights
            .map { key, weight in
                GraphSnapshot.Edge(source: key.low, target: key.high, weight: weight)
            }
            .sorted { ($0.source, $0.target) < ($1.source, $1.target) }

        return GraphSnapshot(nodes: rawNodes, edges: edges)
    }

    /// An undirected edge, normalised so (a,b) and (b,a) collapse to one key.
    private struct EdgeKey: Hashable {
        let low: Int
        let high: Int
        init(_ a: Int, _ b: Int) {
            low = min(a, b)
            high = max(a, b)
        }
    }

    static func normalize(_ target: String) -> String {
        target.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func basename(of path: String) -> String {
        var name = path
        if let slash = name.lastIndex(of: "/") {
            name = String(name[name.index(after: slash)...])
        }
        if name.hasSuffix(".md") { name = String(name.dropLast(3)) }
        return name
    }
}
