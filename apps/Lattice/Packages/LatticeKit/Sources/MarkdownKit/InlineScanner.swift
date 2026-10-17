import Foundation
import VaultCore

/// A single-pass lexer for the wiki syntax `swift-markdown` cannot represent.
///
/// `swift-markdown` wraps cmark-gfm, whose inline grammar is fixed — there is no
/// extension point for `[[wikilinks]]`, `#tags`, or `^block-ids`. So those are scanned
/// here, directly over the source, and the CommonMark structure is left to
/// `swift-markdown` in whatever layer wants a full AST.
///
/// The scanner is code-aware: it tracks fenced blocks, indented code, and inline code
/// spans, and emits nothing from inside them. A `#hashtag` in a shell snippet is a
/// comment, not a tag, and treating it as one would pollute the graph.
///
/// All offsets are UTF-16, which is what TextKit and `NSRange` want.
public struct InlineScanner: Sendable {
    public struct ScanResult: Sendable {
        public var wikilinks: [WikilinkToken] = []
        public var tags: [TagToken] = []
        public var blockIDs: [BlockIDToken] = []
        public var headings: [HeadingToken] = []
    }

    public init() {}

    public func scan(_ source: String, from startOffset: Int = 0) -> ScanResult {
        let units = Array(source.utf16)
        var result = ScanResult()

        var index = max(0, min(startOffset, units.count))
        var atLineStart = true
        var lineStart = index
        var fence: (marker: UInt16, count: Int)?

        while index < units.count {
            let unit = units[index]

            if atLineStart {
                lineStart = index
                let indent = countIndent(units, from: index)

                // Fenced code: ``` or ~~~, closed by a run of >= the opening length.
                if let openFence = fence {
                    if let run = fenceRun(units, at: index + indent),
                       run.marker == openFence.marker, run.count >= openFence.count {
                        fence = nil
                    }
                    index = endOfLine(units, from: index)
                    continue
                }
                if let run = fenceRun(units, at: index + indent), run.count >= 3 {
                    fence = run
                    index = endOfLine(units, from: index)
                    continue
                }
                // Indented code block: four spaces or a tab, but only outside a list.
                if indent >= 4 {
                    index = endOfLine(units, from: index)
                    continue
                }
                if let heading = scanHeading(units, at: index + indent) {
                    result.headings.append(heading)
                    index = endOfLine(units, from: index)
                    continue
                }
                atLineStart = false
            }

            switch unit {
            case UInt16(ascii: "\\"):
                // A backslash escapes the next unit, so `\[[not a link]]` stays text.
                index += 2
                continue

            case UInt16(ascii: "`"):
                index = skipInlineCode(units, from: index)
                continue

            case UInt16(ascii: "\n"):
                if let block = scanBlockID(units, lineStart: lineStart, lineEnd: index) {
                    result.blockIDs.append(block)
                }
                index += 1
                atLineStart = true
                continue

            case UInt16(ascii: "["), UInt16(ascii: "!"):
                if let link = scanWikilink(units, at: index) {
                    result.wikilinks.append(link)
                    index = link.range.upperBound
                    continue
                }
                index += 1
                continue

            case UInt16(ascii: "#"):
                if let tag = scanTag(units, at: index) {
                    result.tags.append(tag)
                    index = tag.range.upperBound
                    continue
                }
                index += 1
                continue

            default:
                index += 1
            }
        }

        // The final line may not be newline-terminated.
        if fence == nil, let block = scanBlockID(units, lineStart: lineStart, lineEnd: units.count) {
            result.blockIDs.append(block)
        }
        return result
    }

    // MARK: - Wikilinks

    /// Parses `[[Target#anchor|Alias]]` and the `![[...]]` embed form.
    ///
    /// Returns `nil` when the brackets do not close on the same line — an unterminated
    /// `[[` is far more likely to be a typo than a link spanning paragraphs.
    private func scanWikilink(_ units: [UInt16], at start: Int) -> WikilinkToken? {
        var index = start
        var isEmbed = false
        if units[index] == UInt16(ascii: "!") {
            isEmbed = true
            index += 1
        }
        guard index + 1 < units.count,
              units[index] == UInt16(ascii: "["),
              units[index + 1] == UInt16(ascii: "[")
        else { return nil }
        index += 2

        let contentStart = index
        while index + 1 < units.count {
            if units[index] == UInt16(ascii: "\n") { return nil }
            if units[index] == UInt16(ascii: "]") && units[index + 1] == UInt16(ascii: "]") {
                break
            }
            index += 1
        }
        guard index + 1 < units.count,
              units[index] == UInt16(ascii: "]"),
              units[index + 1] == UInt16(ascii: "]")
        else { return nil }

        let content = String(decoding: units[contentStart..<index], as: UTF16.self)
        guard let parsed = parseWikilinkContent(content) else { return nil }

        return WikilinkToken(
            target: parsed.target,
            anchor: parsed.anchor,
            alias: parsed.alias,
            isEmbed: isEmbed,
            range: start..<(index + 2)
        )
    }

    /// Splits the inside of a wikilink into target, anchor, and alias.
    ///
    /// Order matters: the alias pipe binds loosest, so `[[A#B|C|D]]` aliases to `C|D`
    /// rather than truncating at the second pipe.
    func parseWikilinkContent(
        _ content: String
    ) -> (target: String, anchor: LinkAnchor, alias: String?)? {
        var body = content
        var alias: String?
        if let pipe = body.firstIndex(of: "|") {
            alias = String(body[body.index(after: pipe)...]).trimmingCharacters(in: .whitespaces)
            body = String(body[body.startIndex..<pipe])
        }

        var anchor: LinkAnchor = .wholeNote
        if let hash = body.firstIndex(of: "#") {
            let fragment = String(body[body.index(after: hash)...])
                .trimmingCharacters(in: .whitespaces)
            body = String(body[body.startIndex..<hash])
            if fragment.hasPrefix("^") {
                anchor = .block(String(fragment.dropFirst()))
            } else if !fragment.isEmpty {
                anchor = .heading(fragment)
            }
        }

        let target = body.trimmingCharacters(in: .whitespaces)
        // `[[#^block]]` is a same-note reference and has an empty target, which is valid.
        if target.isEmpty, case .wholeNote = anchor { return nil }
        return (target, anchor, alias?.nonEmpty)
    }

    // MARK: - Tags

    /// Parses `#tag`, requiring a boundary before the `#` so `C#` and `id#3` are not tags.
    private func scanTag(_ units: [UInt16], at start: Int) -> TagToken? {
        if start > 0, isTagBody(units[start - 1]) { return nil }

        var index = start + 1
        let bodyStart = index
        while index < units.count, isTagBody(units[index]) { index += 1 }
        guard index > bodyStart else { return nil }

        var text = String(decoding: units[bodyStart..<index], as: UTF16.self)
        // Trim separators that trail the tag, e.g. the period in "see #work."
        while let last = text.last, last == "/" || last == "-" || last == "_" {
            text.removeLast()
        }
        guard !text.isEmpty else { return nil }
        // A purely numeric run is a number (`#1`), not a tag.
        guard text.contains(where: { !$0.isNumber && $0 != "/" }) else { return nil }
        guard let tag = Tag(text) else { return nil }

        return TagToken(tag: tag, range: start..<(bodyStart + text.utf16.count))
    }

    private func isTagBody(_ unit: UInt16) -> Bool {
        switch unit {
        case UInt16(ascii: "a")...UInt16(ascii: "z"),
             UInt16(ascii: "A")...UInt16(ascii: "Z"),
             UInt16(ascii: "0")...UInt16(ascii: "9"),
             UInt16(ascii: "-"), UInt16(ascii: "_"), UInt16(ascii: "/"):
            return true
        default:
            // Anything above ASCII is treated as a letter so non-Latin tags work.
            return unit > 127
        }
    }

    // MARK: - Block identifiers

    /// Recognises a trailing `^block-id` on a line, which names the block for `[[#^id]]`.
    private func scanBlockID(_ units: [UInt16], lineStart: Int, lineEnd: Int) -> BlockIDToken? {
        var end = lineEnd
        while end > lineStart, units[end - 1] == UInt16(ascii: "\r")
            || units[end - 1] == UInt16(ascii: " ")
            || units[end - 1] == UInt16(ascii: "\t") {
            end -= 1
        }
        var index = end
        while index > lineStart, isBlockIDBody(units[index - 1]) { index -= 1 }
        guard index > lineStart, units[index - 1] == UInt16(ascii: "^"), index < end else {
            return nil
        }
        let caret = index - 1
        // The caret must be preceded by whitespace, otherwise it is `x^2`.
        guard caret > lineStart,
              units[caret - 1] == UInt16(ascii: " ") || units[caret - 1] == UInt16(ascii: "\t")
        else { return nil }

        let identifier = String(decoding: units[index..<end], as: UTF16.self)
        return BlockIDToken(
            identifier: identifier,
            range: caret..<end,
            blockRange: lineStart..<(caret - 1)
        )
    }

    private func isBlockIDBody(_ unit: UInt16) -> Bool {
        switch unit {
        case UInt16(ascii: "a")...UInt16(ascii: "z"),
             UInt16(ascii: "A")...UInt16(ascii: "Z"),
             UInt16(ascii: "0")...UInt16(ascii: "9"),
             UInt16(ascii: "-"):
            return true
        default:
            return false
        }
    }

    // MARK: - Headings

    private func scanHeading(_ units: [UInt16], at start: Int) -> HeadingToken? {
        var index = start
        var level = 0
        while index < units.count, units[index] == UInt16(ascii: "#"), level < 7 {
            level += 1
            index += 1
        }
        guard level >= 1, level <= 6 else { return nil }
        // ATX headings require a space after the hashes; without it this is a tag.
        guard index < units.count,
              units[index] == UInt16(ascii: " ") || units[index] == UInt16(ascii: "\t")
        else { return nil }

        let lineEnd = endOfLineExcludingTerminator(units, from: index)
        let text = String(decoding: units[index..<lineEnd], as: UTF16.self)
            .trimmingCharacters(in: .whitespaces)
        return HeadingToken(level: level, text: text, range: start..<lineEnd)
    }

    // MARK: - Cursor helpers

    private func countIndent(_ units: [UInt16], from: Int) -> Int {
        var index = from
        var width = 0
        while index < units.count {
            if units[index] == UInt16(ascii: " ") { width += 1 }
            else if units[index] == UInt16(ascii: "\t") { width += 4 }
            else { break }
            index += 1
        }
        return width
    }

    private func fenceRun(_ units: [UInt16], at start: Int) -> (marker: UInt16, count: Int)? {
        guard start < units.count else { return nil }
        let marker = units[start]
        guard marker == UInt16(ascii: "`") || marker == UInt16(ascii: "~") else { return nil }
        var index = start
        var count = 0
        while index < units.count, units[index] == marker {
            count += 1
            index += 1
        }
        return count >= 3 ? (marker, count) : nil
    }

    /// Skips a `` `code span` ``, matching the opening backtick run length.
    private func skipInlineCode(_ units: [UInt16], from start: Int) -> Int {
        var index = start
        var openCount = 0
        while index < units.count, units[index] == UInt16(ascii: "`") {
            openCount += 1
            index += 1
        }
        var run = 0
        while index < units.count {
            if units[index] == UInt16(ascii: "\n") && run == 0 {
                // Code spans do not cross blank lines; treat the newline as a terminator.
                return index
            }
            if units[index] == UInt16(ascii: "`") {
                run += 1
                if run == openCount {
                    return index + 1
                }
            } else {
                run = 0
            }
            index += 1
        }
        return index
    }

    private func endOfLine(_ units: [UInt16], from: Int) -> Int {
        var index = from
        while index < units.count, units[index] != UInt16(ascii: "\n") { index += 1 }
        return min(index + 1, units.count)
    }

    private func endOfLineExcludingTerminator(_ units: [UInt16], from: Int) -> Int {
        var index = from
        while index < units.count, units[index] != UInt16(ascii: "\n") { index += 1 }
        return index
    }
}
