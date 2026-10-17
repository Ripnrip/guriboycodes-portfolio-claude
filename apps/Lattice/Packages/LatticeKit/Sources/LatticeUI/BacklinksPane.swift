import GraphEngine
import SwiftUI
import VaultCore
import VaultIndex

/// What links to the note you are reading.
///
/// Backlinks are the payoff of the whole link index: they turn a folder of files into a
/// web you can traverse in both directions, which is the difference between notes and a
/// knowledge base.
public struct BacklinksPane: View {
    @Bindable var controller: VaultController

    public init(controller: VaultController) {
        self.controller = controller
    }

    public var body: some View {
        List {
            if let note = controller.selectedNote {
                Section("Backlinks") {
                    if controller.backlinks.isEmpty {
                        Text("Nothing links here yet.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(controller.backlinks) { backlink in
                            Button {
                                controller.selectNote(id: backlink.source.id)
                            } label: {
                                BacklinkRow(backlink: backlink)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !note.tags.isEmpty {
                    Section("Tags") {
                        ForEach(note.tags, id: \.self) { tag in
                            Text(tag.display).font(.callout)
                        }
                    }
                }

                Section("Graph") {
                    LabeledContent("Notes", value: controller.graphModel.snapshot.nodeCount.formatted())
                    LabeledContent("Links", value: controller.graphModel.snapshot.edgeCount.formatted())
                }
            } else {
                Text("No note selected.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct BacklinkRow: View {
    let backlink: Backlink

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(backlink.source.title)
                .font(.callout.weight(.medium))
            // Show how the link was written — an alias or a heading anchor tells you why
            // the other note is pointing here, which the title alone does not.
            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    private var detail: String? {
        var parts: [String] = []
        if let alias = backlink.link.alias { parts.append("“\(alias)”") }
        switch backlink.link.anchor {
        case .wholeNote: break
        case .heading(let heading): parts.append("# \(heading)")
        case .block: parts.append("block reference")
        }
        if backlink.link.kind == .embed { parts.append("embedded") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
