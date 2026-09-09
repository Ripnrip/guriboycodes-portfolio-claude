import Foundation
import VaultCore

/// Everything the index needs from one Markdown file, derived in a single parse.
public struct ParsedNote: Sendable {
    public let frontmatter: Frontmatter
    public let title: String
    public let aliases: [String]
    /// Tags from frontmatter and body, deduplicated and sorted.
    public let tags: [Tag]
    public let wikilinks: [WikilinkToken]
    public let blockIDs: [BlockIDToken]
    public let headings: [HeadingToken]
    public let excerpt: String
    public let wordCount: Int
    /// UTF-16 offset where the body begins, i.e. just past the frontmatter.
    public let bodyStartOffset: Int

    /// Converts this note's wikilinks into store-ready link rows.
    public func links(from source: NoteID) -> [LinkSnapshot] {
        wikilinks.map { token in
            LinkSnapshot(
                source: source,
                target: token.target,
                anchor: token.anchor,
                alias: token.alias,
                kind: token.kind,
                range: token.range
            )
        }
    }
}

/// Turns Markdown source into a ``ParsedNote``.
public struct NoteParser: Sendable {
    private let scanner = InlineScanner()

    public init() {}

    /// - Parameters:
    ///   - source: The full file contents, frontmatter included.
    ///   - filename: Basename without extension, used as the last-resort title.
    public func parse(_ source: String, filename: String) -> ParsedNote {
        let frontmatter = Frontmatter.parse(source)
        let scanned = scanner.scan(source, from: frontmatter.bodyStartOffset)

        // Title precedence: frontmatter, then the first H1, then the filename. The
        // filename fallback is what makes a plain Obsidian vault work with no metadata.
        let title = frontmatter.title
            ?? scanned.headings.first(where: { $0.level == 1 })?.text.nonEmpty
            ?? filename

        var tags: Set<Tag> = []
        for raw in frontmatter.tagStrings {
            if let tag = Tag(raw) { tags.insert(tag) }
        }
        for token in scanned.tags { tags.insert(token.tag) }

        let body = Self.bodyText(of: source, from: frontmatter.bodyStartOffset)

        return ParsedNote(
            frontmatter: frontmatter,
            title: title,
            aliases: frontmatter.aliases,
            tags: tags.sorted(),
            wikilinks: scanned.wikilinks,
            blockIDs: scanned.blockIDs,
            headings: scanned.headings,
            excerpt: Self.excerpt(from: body),
            wordCount: body.split(whereSeparator: { $0.isWhitespace }).count,
            bodyStartOffset: frontmatter.bodyStartOffset
        )
    }

    private static func bodyText(of source: String, from offset: Int) -> String {
        let units = Array(source.utf16)
        guard offset > 0, offset < units.count else {
            return offset >= units.count ? "" : source
        }
        return String(decoding: units[offset...], as: UTF16.self)
    }

    /// A plain-text lead-in for list rows: the first prose paragraph, stripped of the
    /// markup that would otherwise show up as literal punctuation in a subtitle.
    static func excerpt(from body: String, limit: Int = 200) -> String {
        for rawLine in body.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") || line.hasPrefix(">")
                || line.hasPrefix("---") || line.hasPrefix("```") {
                continue
            }
            let cleaned = strippingInlineMarkup(line)
            if cleaned.isEmpty { continue }
            return cleaned.count > limit
                ? String(cleaned.prefix(limit)).trimmingCharacters(in: .whitespaces) + "…"
                : cleaned
        }
        return ""
    }

    /// Removes the markup characters that read as noise in a one-line summary, keeping
    /// the human-facing text of links.
    static func strippingInlineMarkup(_ line: String) -> String {
        var output = ""
        let characters = Array(line)
        var index = 0
        while index < characters.count {
            let character = characters[index]
            // `[[Target|Alias]]` and `![[Target]]` reduce to the display text.
            if character == "[" || character == "!" {
                let bracketStart = character == "!" ? index + 1 : index
                if bracketStart + 1 < characters.count,
                   characters[bracketStart] == "[", characters[bracketStart + 1] == "[",
                   let close = closingDoubleBracket(characters, from: bracketStart + 2) {
                    let inner = String(characters[(bracketStart + 2)..<close])
                    let display = inner.split(separator: "|").last.map(String.init) ?? inner
                    output += display.split(separator: "#").first.map(String.init) ?? display
                    index = close + 2
                    continue
                }
            }
            if character == "*" || character == "_" || character == "`" || character == "~" {
                index += 1
                continue
            }
            output.append(character)
            index += 1
        }
        return output.trimmingCharacters(in: .whitespaces)
    }

    private static func closingDoubleBracket(_ characters: [Character], from: Int) -> Int? {
        var index = from
        while index + 1 < characters.count {
            if characters[index] == "]" && characters[index + 1] == "]" { return index }
            index += 1
        }
        return nil
    }
}
