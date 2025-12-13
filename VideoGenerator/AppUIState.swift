import Foundation

@MainActor
final class AppUIState: ObservableObject {
    @Published var showingAddModelSheet = false
    @Published var showingDirectoryPicker = false

    func showAddModelSheet() {
        showingAddModelSheet = true
    }

    func hideAddModelSheet() {
        showingAddModelSheet = false
    }

    func showDirectoryPicker() {
        showingDirectoryPicker = true
    }

    func hideDirectoryPicker() {
        showingDirectoryPicker = false
    }
}
