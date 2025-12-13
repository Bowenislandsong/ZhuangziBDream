import SwiftUI

@main
struct VideoGeneratorApp: App {
    @StateObject private var modelManager = ModelManager()
    @StateObject private var uiState = AppUIState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(modelManager)
                .environmentObject(uiState)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Download Model…") {
                    uiState.showAddModelSheet()
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
        }
    }
}
