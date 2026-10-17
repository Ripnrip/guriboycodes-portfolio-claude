import Foundation
import MarkdownKit
import VaultCore

/// Rewrites `[[wikilinks]]` when a note is renamed or moved.
///
/// Renaming a note silently breaks every link to it, so repair is part of the rename, not
/// a maintenance command. The rewrite goes through ``InlineScanner`` rather than a regex
/// or a string replace, which buys two things: a `[[Link]]` inside a code fence is left
/// alone, and each token is rebuilt from its parsed parts so anchors and aliases survive —
/// `[[Old#Heading|shown as this]]` keeps both halves.
public struct LinkRewriter: Sendable {
    private static let scanner = InlineScanner()

    /// Returns the rewritten source, or `nil` when nothing matched.
    ///
    /// - Parameters:
    ///   - oldTargets: Normalised forms the old note answered to — see ``targetForms``.
    ///   - newTarget: What to write in their place, e.g. `Projects/New Name`.
    public static func rewriting(
        _ source: String,
        matching oldTargets: Set<String>,
        to newTarget: String
    ) -> String? {
        guard !oldTargets.isEmpty else { return nil }

        let matches = scanner.scan(source).wikilinks.filter {
            oldTargets.contains(LinkResolver.normalize($0.target))
        }
        guard !matches.isEmpty else { return nil }

        var units = Array(source.utf16)
        // Back to front, so each replacement leaves the earlier ranges valid.
        for token in matches.sorted(by: { $0.range.lowerBound > $1.range.lowerBound }) {
            let replacement = Array(render(token, target: newTarget).utf16)
            units.replaceSubrange(token.range, with: replacement)
        }
        return String(decoding: units, as: UTF16.self)
    }

    /// Every normalised form a note answers to when resolving links.
    ///
    /// Mirrors ``LinkResolver``'s precedence, so a rename repairs exactly the links that
    /// resolution would have matched — no more, no less.
    public static func targetForms(
        relativePath: String,
        title: String,
        aliases: [String] = []
    ) -> Set<String> {
        var forms: Set<String> = [
            LinkResolver.normalize(relativePath),
            LinkResolver.normalize(title),
        ]
        for alias in aliases {
            forms.insert(LinkResolver.normalize(alias))
        }
        let withoutExtension = relativePath.hasSuffix(".md")
            ? String(relativePath.dropLast(3))
            : relativePath
        forms.insert(LinkResolver.normalize(withoutExtension))
        // Bare basename, which is how most links are written.
        if let slash = withoutExtension.lastIndex(of: "/") {
            forms.insert(
                LinkResolver.normalize(String(withoutExtension[withoutExtension.index(after: slash)...]))
            )
        }
        forms.remove("")
        return forms
    }

    /// Rebuilds a wikilink's source text with a different target.
    private static func render(_ token: WikilinkToken, target: String) -> String {
        var text = token.isEmbed ? "![[" : "[["
        text += target
        switch token.anchor {
        case .wholeNote:
            break
        case .heading(let heading):
            text += "#" + heading
        case .block(let identifier):
            text += "#^" + identifier
        }
        if let alias = token.alias {
            text += "|" + alias
        }
        return text + "]]"
    }
}
