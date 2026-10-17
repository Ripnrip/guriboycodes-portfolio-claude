import GraphEngine
import SwiftUI
import VaultCore

/// The middle column: notes matching the sidebar filter, searchable.
public struct NoteListView: View {
    @Bindable var controller: VaultController
    let filter: VaultFilter

    @State private var query = ""
    @State private var tagFilteredNotes: [NoteSnapshot] = []

    public init(controller: VaultController, filter: VaultFilter) {
        self.controller = controller
        self.filter = filter
    }

    public var body: some View {
        List(selection: selectionBinding) {
            if case .unresolved = filter {
                missingNotesSection
            } else {
                ForEach(visibleNotes) { note in
                    NoteRow(note: note).tag(note.id)
                }
            }
        }
        .searchable(text: $query, prompt: "Search notes")
        .overlay {
            if visibleNotes.isEmpty, !isUnresolvedFilter {
                ContentUnavailableView.search(text: query)
                    .opacity(query.isEmpty ? 0 : 1)
            }
        }
        .task(id: filter) { await loadTagFilter() }
        .navigationTitle(title)
    }

    private var missingNotesSection: some View {
        Section {
            ForEach(controller.unresolvedTargets, id: \.self) { target in
                // A link with nowhere to point is an invitation, so offer the obvious
                // next action right here rather than making the user go and create it.
                Button {
                    Task { await createAndOpen(target) }
                } label: {
                    Label(target, systemImage: "plus.circle")
                }
                .buttonStyle(.plain)
            }
        } footer: {
            Text("Links that point at notes you haven't written yet.")
        }
    }

    private var selectionBinding: Binding<NoteID?> {
        Binding(
            get: { controller.selectedNote?.id },
            set: { id in
                guard let id else {
                    controller.select(nil)
                    return
                }
                controller.selectNote(id: id)
            }
        )
    }

    private var isUnresolvedFilter: Bool {
        if case .unresolved = filter { return true }
        return false
    }

    private var visibleNotes: [NoteSnapshot] {
        let base: [NoteSnapshot]
        switch filter {
        case .allNotes, .unresolved:
            base = controller.notes
        case .tag:
            base = tagFilteredNotes
        case .orphans:
            let orphanIDs = Set(
                controller.graphModel.snapshot.orphanIndices.map {
                    controller.graphModel.snapshot.nodes[$0].id
                }
            )
            base = controller.notes.filter { orphanIDs.contains($0.id) }
        }

        guard !query.isEmpty else { return base }
        let needle = query.lowercased()
        return base.filter {
            $0.title.lowercased().contains(needle)
                || $0.excerpt.lowercased().contains(needle)
                || $0.aliases.contains { $0.lowercased().contains(needle) }
        }
    }

    private var title: String {
        switch filter {
        case .allNotes: return "All Notes"
        case .tag(let tag): return tag.display
        case .orphans: return "Unlinked"
        case .unresolved: return "Missing"
        }
    }

    private func loadTagFilter() async {
        guard case .tag(let tag) = filter else {
            tagFilteredNotes = []
            return
        }
        tagFilteredNotes = await controller.notes(withTag: tag)
    }

    private func createAndOpen(_ target: String) async {
        if let note = await controller.createNote(titled: target) {
            controller.select(note)
        }
    }
}

private struct NoteRow: View {
    let note: NoteSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(note.title)
                .font(.body.weight(.medium))
                .lineLimit(1)
            if !note.excerpt.isEmpty {
                Text(note.excerpt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if !note.tags.isEmpty {
                Text(note.tags.prefix(4).map(\.display).joined(separator: " "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
