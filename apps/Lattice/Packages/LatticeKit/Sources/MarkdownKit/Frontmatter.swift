import Foundation

/// A value read from YAML frontmatter.
///
/// Deliberately only two shapes. Frontmatter in a notes app is overwhelmingly flat
/// key/value and key/list; supporting nested maps would mean vendoring a real YAML
/// engine for a case that essentially never appears in a vault.
public enum FrontmatterValue: Hashable, Sendable {
    case scalar(String)
    case list([String])

    /// The value as a single string, joining lists with commas.
    public var stringValue: String {
        switch self {
        case .scalar(let text): return text
        case .list(let items): return items.joined(separator: ", ")
        }
    }

    /// The value as a list; a scalar becomes a single-element list.
    public var listValue: [String] {
        switch self {
        case .scalar(let text): return text.isEmpty ? [] : [text]
        case .list(let items): return items
        }
    }

    public var boolValue: Bool? {
        switch stringValue.lowercased() {
        case "true", "yes", "on": return true
        case "false", "no", "off": return false
        default: return nil
        }
    }
}

/// The YAML block delimited by `---` at the very top of a note.
///
/// ### Supported subset
/// ```yaml
/// ---
/// id: 4f3c...            # scalar, quotes optional
/// title: "My: Note"      # quoted scalar keeps the colon
/// aliases: [Foo, Bar]    # inline list
/// tags:                  # block list
///   - project
///   - area/work
/// pinned: true
/// ---
/// ```
/// Nested maps, anchors, multi-line scalars, and flow maps are **not** supported and are
/// preserved verbatim in ``raw`` so a round-trip never destroys them.
public struct Frontmatter: Hashable, Sendable {
    public private(set) var values: [String: FrontmatterValue]
    /// The original YAML text, without the `---` fences.
    public let raw: String
    /// UTF-16 offset in the source at which the note body begins.
    public let bodyStartOffset: Int

    public static let empty = Frontmatter(values: [:], raw: "", bodyStartOffset: 0)

    public init(values: [String: FrontmatterValue], raw: String, bodyStartOffset: Int) {
        self.values = values
        self.raw = raw
        self.bodyStartOffset = bodyStartOffset
    }

    public subscript(key: String) -> FrontmatterValue? { values[key.lowercased()] }

    public var id: String? { self["id"]?.stringValue.nonEmpty }
    public var title: String? { self["title"]?.stringValue.nonEmpty }
    public var aliases: [String] { self["aliases"]?.listValue ?? self["alias"]?.listValue ?? [] }
    public var tagStrings: [String] { self["tags"]?.listValue ?? self["tag"]?.listValue ?? [] }

    /// Splits a document into its frontmatter and the offset where the body starts.
    ///
    /// A `---` fence only opens frontmatter when it is the very first line, which is what
    /// keeps a horizontal rule in the middle of a note from being misread as YAML.
    public static func parse(_ source: String) -> Frontmatter {
        let units = Array(source.utf16)
        guard units.count >= 3 else { return .empty }

        var cursor = 0
        guard matchesFence(units, at: &cursor) else { return .empty }

        let yamlStart = cursor
        // Find the closing fence, which must sit at the start of its own line.
        var closingStart: Int?
        var closingEnd = units.count
        var lineStart = cursor
        while lineStart < units.count {
            var probe = lineStart
            if matchesFence(units, at: &probe) {
                closingStart = lineStart
                closingEnd = probe
                break
            }
            lineStart = endOfLine(units, from: lineStart)
        }

        guard let yamlEnd = closingStart else { return .empty }
        let yaml = String(decoding: units[yamlStart..<yamlEnd], as: UTF16.self)
        return Frontmatter(
            values: parseYAML(yaml),
            raw: yaml,
            bodyStartOffset: closingEnd
        )
    }

    /// Consumes a `---` line at `cursor`, advancing past its newline. Returns false and
    /// leaves `cursor` untouched when the line is not a fence.
    private static func matchesFence(_ units: [UInt16], at cursor: inout Int) -> Bool {
        var i = cursor
        var dashes = 0
        while i < units.count, units[i] == UInt16(ascii: "-") {
            dashes += 1
            i += 1
        }
        guard dashes == 3 else { return false }
        // Only trailing whitespace may follow.
        while i < units.count, units[i] == UInt16(ascii: " ") || units[i] == UInt16(ascii: "\t") {
            i += 1
        }
        guard i >= units.count || units[i] == UInt16(ascii: "\n") || units[i] == UInt16(ascii: "\r")
        else { return false }
        cursor = endOfLine(units, from: i)
        return true
    }

    /// Index just past the newline that ends the line containing `from`.
    private static func endOfLine(_ units: [UInt16], from: Int) -> Int {
        var i = from
        while i < units.count, units[i] != UInt16(ascii: "\n") { i += 1 }
        return min(i + 1, units.count)
    }

    private static func parseYAML(_ yaml: String) -> [String: FrontmatterValue] {
        var result: [String: FrontmatterValue] = [:]
        var pendingKey: String?
        var pendingItems: [String] = []

        func flushPending() {
            if let key = pendingKey, !pendingItems.isEmpty {
                result[key] = .list(pendingItems)
            }
            pendingKey = nil
            pendingItems = []
        }

        for rawLine in yaml.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(rawLine)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            // A block-list item continues the key we saw last.
            if trimmed.hasPrefix("- "), pendingKey != nil {
                pendingItems.append(unquote(String(trimmed.dropFirst(2))))
                continue
            }
            if trimmed == "-" { continue }

            guard let colon = indexOfKeySeparator(trimmed) else {
                flushPending()
                continue
            }
            flushPending()

            let key = String(trimmed[trimmed.startIndex..<colon])
                .trimmingCharacters(in: .whitespaces)
                .lowercased()
            let rest = String(trimmed[trimmed.index(after: colon)...])
                .trimmingCharacters(in: .whitespaces)

            if rest.isEmpty {
                // Either an empty value or the header of a block list; decide on the next line.
                pendingKey = key
                result[key] = .scalar("")
            } else if rest.hasPrefix("["), rest.hasSuffix("]") {
                let inner = String(rest.dropFirst().dropLast())
                let items = inner
                    .split(separator: ",")
                    .map { unquote(String($0).trimmingCharacters(in: .whitespaces)) }
                    .filter { !$0.isEmpty }
                result[key] = .list(items)
            } else {
                result[key] = .scalar(unquote(rest))
            }
        }
        flushPending()
        return result
    }

    /// Finds the `:` that separates key from value, ignoring colons inside quotes.
    private static func indexOfKeySeparator(_ line: String) -> String.Index? {
        var inSingle = false
        var inDouble = false
        var index = line.startIndex
        while index < line.endIndex {
            let character = line[index]
            if character == "'" && !inDouble { inSingle.toggle() }
            if character == "\"" && !inSingle { inDouble.toggle() }
            if character == ":" && !inSingle && !inDouble { return index }
            index = line.index(after: index)
        }
        return nil
    }

    private static func unquote(_ text: String) -> String {
        var value = text.trimmingCharacters(in: .whitespaces)
        // Strip a trailing inline comment only when the value is unquoted.
        if !value.hasPrefix("\"") && !value.hasPrefix("'"),
           let hash = value.range(of: " #") {
            value = String(value[value.startIndex..<hash.lowerBound])
                .trimmingCharacters(in: .whitespaces)
        }
        if value.count >= 2 {
            let first = value.first
            let last = value.last
            if (first == "\"" && last == "\"") || (first == "'" && last == "'") {
                value = String(value.dropFirst().dropLast())
            }
        }
        return value
    }
}

extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
