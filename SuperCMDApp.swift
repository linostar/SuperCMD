import SwiftUI

@main
struct SuperCMDApp: App {
    // Initialize the database manager as a state object to be used throughout the app
    @StateObject private var dataManager = DataManager.shared

    var body: some Scene {
        // Creates an icon in the menu bar.
        MenuBarExtra("SuperCMD", systemImage: "terminal") {
            // The ContentView is presented when the user clicks the menu bar icon.
            ContentView()
                .environmentObject(dataManager) // Pass the data manager to the views
        }
        .menuBarExtraStyle(.window) // Use a popover-style window for the menu.
    }
}
