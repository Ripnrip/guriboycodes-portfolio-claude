import LatticeUI
import SwiftUI

@main
@MainActor
struct LatticeApp: App {
    @State private var controller = VaultController()

    var body: some Scene {
        WindowGroup {
            VaultWindow(controller: controller)
        }
        #if os(macOS)
        .defaultSize(width: 1280, height: 860)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Note") {
                    Task { await controller.createNote(titled: "Untitled") }
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(after: .toolbar) {
                Button("Fit Graph to Window") { controller.graphModel.fitToContent() }
                    .keyboardShortcut("0", modifiers: .command)
                Button("Restart Layout") { controller.graphModel.reheat() }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                Divider()
                Button("Reindex Vault") {
                    Task { await controller.refresh() }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
        #endif
    }
}
