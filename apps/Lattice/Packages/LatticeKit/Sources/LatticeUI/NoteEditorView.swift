import SwiftUI
import VaultCore

/// The note editor, with `[[` link completion.
///
/// ### On the completion heuristic
/// SwiftUI's `TextEditor` exposes no cursor position, so completion is driven by finding
/// the last unclosed `[[` in the text. That is exact while typing at the end of a note —
/// the overwhelmingly common case — and simply shows nothing when editing mid-document.
/// Cursor-accurate completion needs an `NSTextView`/`UITextView` bridge, which is deferred
/// rather than faked: a popover anchored to the wrong glyph is worse than no popover.
public struct NoteEditorView: View {
    @Bindable var controller: VaultController

    @State private var suggestions: [NoteSnapshot] = []
    @State private var suggestionQuery = ""
    @FocusState private var isEditorFocused: Bool

    public init(controller: VaultController) {
        self.controller = controller
    }

    public var body: some View {
        Group {
            if let note = controller.selectedNote {
                editor(for: note)
            } else {
                ContentUnavailableView(
                    "No note selected",
                    systemImage: "doc.text",
                    description: Text("Pick a note, or follow a link in the graph.")
                )
            }
        }
    }

    private func editor(for note: NoteSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(for: note)
            Divider()

            TextEditor(text: textBinding)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .focused($isEditorFocused)
                .padding(.horizontal, 4)

            if !suggestions.isEmpty {
                Divider()
                suggestionList
            }
        }
        .task(id: suggestionQuery) { await loadSuggestions() }
        .onDisappear { Task { await controller.saveSelectedNote() } }
        .toolbar {
            ToolbarItem {
                Button {
                    Task { await controller.saveSelectedNote() }
                } label: {
                    Label("Save", systemImage: "arrow.down.doc")
                }
                .keyboardShortcut("s", modifiers: .command)
            }
        }
    }

    private func header(for note: NoteSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title).font(.title2.weight(.semibold))
            HStack(spacing: 8) {
                Text(note.relativePath)
                Text("·")
                Text("\(note.wordCount) words")
                if !note.aliases.isEmpty {
                    Text("·")
                    Text("also: \(note.aliases.joined(separator: ", "))")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var suggestionList: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(suggestions) { note in
                    Button(note.title) {
                        insert(note)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(6)
        }
        .frame(height: 44)
        .accessibilityLabel("Link suggestions")
    }

    private var textBinding: Binding<String> {
        Binding(
            get: { controller.editorText },
            set: { text in
                controller.updateEditorText(text)
                suggestionQuery = Self.activeLinkQuery(in: text)?.query ?? ""
            }
        )
    }

    private func loadSuggestions() async {
        guard !suggestionQuery.isEmpty else {
            suggestions = []
            return
        }
        suggestions = await controller.suggestions(for: suggestionQuery)
    }

    /// Replaces the in-progress `[[query` with a finished link.
    private func insert(_ note: NoteSnapshot) {
        let text = controller.editorText
        guard let active = Self.activeLinkQuery(in: text) else { return }
        var updated = text
        updated.replaceSubrange(active.range, with: "[[\(note.title)]]")
        controller.updateEditorText(updated)
        suggestionQuery = ""
        suggestions = []
    }

    /// The trailing unclosed `[[…` in `text`, if there is one.
    ///
    /// Bails out on a newline or a closing `]]`, so a finished link earlier in the note
    /// never looks like an in-progress one.
    static func activeLinkQuery(in text: String) -> (range: Range<String.Index>, query: String)? {
        guard let open = text.range(of: "[[", options: .backwards) else { return nil }
        let tail = text[open.upperBound...]
        guard !tail.contains("]]"), !tail.contains("\n") else { return nil }
        return (open.lowerBound..<text.endIndex, String(tail))
    }
}
