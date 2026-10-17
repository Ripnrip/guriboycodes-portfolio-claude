import GraphEngine
import SwiftUI
import VaultCore

/// What the sidebar is currently filtering the note list by.
public enum VaultFilter: Hashable, Sendable {
    case allNotes
    case tag(Tag)
    case orphans
    case unresolved
}

/// Folders, tags, and the two views that matter most in a knowledge base: notes nothing
/// links to, and links pointing at notes that do not exist yet.
public struct VaultSidebar: View {
    @Bindable var controller: VaultController
    @Binding var filter: VaultFilter

    public init(controller: VaultController, filter: Binding<VaultFilter>) {
        self.controller = controller
        self._filter = filter
    }

    public var body: some View {
        List(selection: $filter) {
            Section {
                Label("All Notes", systemImage: "doc.text")
                    .badge(controller.notes.count)
                    .tag(VaultFilter.allNotes)

                // Orphans and unresolved links are the two things a vault hides from you:
                // what you wrote and never connected, and what you gestured at and never
                // wrote. Both deserve a permanent home rather than a search.
                Label("Unlinked Notes", systemImage: "circle.dashed")
                    .badge(orphanCount)
                    .tag(VaultFilter.orphans)

                Label("Missing Notes", systemImage: "questionmark.circle")
                    .badge(controller.unresolvedTargets.count)
                    .tag(VaultFilter.unresolved)
            }

            if !controller.tags.isEmpty {
                Section("Tags") {
                    ForEach(controller.tags) { entry in
                        Label {
                            Text(entry.tag.leaf)
                        } icon: {
                            Image(systemName: "number")
                        }
                        // Indented by depth so nested tags read as a hierarchy without
                        // needing a real outline, which `List` selection makes awkward.
                        .padding(.leading, CGFloat(entry.tag.components.count - 1) * 12)
                        .badge(entry.count)
                        .tag(VaultFilter.tag(entry.tag))
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if controller.isIndexing {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Indexing…").font(.caption).foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.bar)
            }
        }
    }

    private var orphanCount: Int {
        controller.graphModel.snapshot.orphanIndices.count
    }
}
