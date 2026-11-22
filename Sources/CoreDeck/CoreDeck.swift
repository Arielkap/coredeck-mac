import SwiftUI

@main
struct CoreDeckApp: App {
    @StateObject private var state = AppState()
    
    var body: some Scene {
        MenuBarExtra {
            CoreDeckView(state: state)
        } label: {
            Text(state.menuBarText)
        }
        .menuBarExtraStyle(.window)
        
        Window("CoreDeck — VPS", id: "vps-manager") {
            ServerManagerWindow(state: state)
        }
        .windowResizability(.contentSize)
    }
}
