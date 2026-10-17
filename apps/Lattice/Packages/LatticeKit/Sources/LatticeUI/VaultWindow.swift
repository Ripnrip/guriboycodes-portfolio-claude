import GraphEngine
import SwiftUI
import VaultCore
import VaultFiles

/// The app's main window: sidebar, note list, and a detail area that toggles between the
/// editor and the graph.
public struct VaultWindow: View {
    @Bindable var controller: VaultController

    @State private var filter: VaultFilter = .allNotes
    @State private var detail: DetailMode = .graph
    @State private var isPickingFolder = false
    @State private var showsInspector = true
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    enum DetailMode: String, CaseIterable, Identifiable {
        case editor = "Note"
        case graph = "Graph"
        var id: String { rawValue }
    }

    public init(controller: VaultController) {
        self.controller = controller
    }

    public var body: some View {
        NavigationSplitView {
            VaultSidebar(controller: controller, filter: $filter)
                .navigationSplitViewColumnWidth(min: 200, ideal: 230)
        } content: {
            NoteListView(controller: controller, filter: filter)
                .navigationSplitViewColumnWidth(min: 240, ideal: 300)
        } detail: {
            detailView
        }
        .task { await openInitialVault() }
        .onChange(of: scenePhase) { _, phase in
            // The only thing keeping the index fresh on iOS, and on macOS it covers edits
            // made while the app was backgrounded and FSEvents was not running.
            if phase == .active { controller.applicationBecameActive() }
        }
        .onChange(of: colorScheme, initial: true) { _, scheme in
            controller.graphModel.style = scheme == .dark ? .dark : .light
        }
        .fileImporter(
            isPresented: $isPickingFolder,
            allowedContentTypes: [.folder]
        ) { result in
            guard case .success(let url) = result else { return }
            Task { await controller.open(url) }
        }
        .alert(
            "Couldn't open the vault",
            isPresented: Binding(
                get: { isFailed },
                set: { presented in
                    if !presented { controller.clearFailure() }
                }
            ),
            presenting: failureMessage
        ) { _ in
            Button("Choose Folder…") { isPickingFolder = true }
            Button("Cancel", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    private var detailView: some View {
        Group {
            switch controller.state {
            case .noVault:
                welcome
            case .opening:
                ProgressView("Indexing vault…")
            case .ready, .failed:
                content
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("View", selection: $detail) {
                    ForEach(DetailMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .disabled(!isReady)
            }
            ToolbarItem {
                Button { isPickingFolder = true } label: {
                    Label("Open Vault", systemImage: "folder")
                }
            }
            ToolbarItem {
                Button { showsInspector.toggle() } label: {
                    Label("Inspector", systemImage: "sidebar.trailing")
                }
                .disabled(!isReady)
            }
        }
        .inspector(isPresented: $showsInspector) {
            BacklinksPane(controller: controller)
                .inspectorColumnWidth(min: 220, ideal: 260, max: 360)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch detail {
        case .editor:
            NoteEditorView(controller: controller)
        case .graph:
            GraphCanvas(model: controller.graphModel)
        }
    }

    private var welcome: some View {
        ContentUnavailableView {
            Label("No vault open", systemImage: "square.grid.3x3.topleft.filled")
        } description: {
            Text(
                """
                Open a folder of Markdown files. Lattice reads and writes the same \
                format Obsidian does, so an existing vault works as-is.
                """
            )
        } actions: {
            Button("Open Folder…") { isPickingFolder = true }
                .buttonStyle(.borderedProminent)
            if controller.usesPollingOnly {
                // Say this up front rather than letting someone discover it: on iOS there
                // is no reliable recursive file watcher, so edits made elsewhere appear
                // when the app next becomes active.
                Text("External edits refresh when Lattice becomes active.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var isReady: Bool {
        if case .ready = controller.state { return true }
        return false
    }

    private var isFailed: Bool {
        if case .failed = controller.state { return true }
        return false
    }

    private var failureMessage: String? {
        if case .failed(let message) = controller.state { return message }
        return nil
    }

    private func openInitialVault() async {
        guard case .noVault = controller.state else { return }
        await controller.restoreLastVault()
    }
}
