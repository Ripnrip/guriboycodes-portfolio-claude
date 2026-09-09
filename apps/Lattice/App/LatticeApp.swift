import GraphEngine
import SwiftUI

@main
@MainActor
struct LatticeApp: App {
    @State private var model = GraphViewModel.demo(nodeCount: 600)

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 820)
        .commands {
            CommandGroup(after: .toolbar) {
                Button("Fit Graph to Window") { model.fitToContent() }
                    .keyboardShortcut("0", modifiers: .command)
                Button("Restart Layout") { model.reheat() }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
        #endif
    }
}
