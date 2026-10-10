import SwiftUI

@main
struct ToolbeltApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            PanelView()
                .environment(appDelegate.appState)
        } label: {
            MenuBarIcon()
                .environment(appDelegate.appState)
        }
        .menuBarExtraStyle(.window)
    }
}

/// The icon in the menu bar. Reads state in a view so it updates when a module changes.
private struct MenuBarIcon: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Image(systemName: appState.menuBarSymbol)
            .accessibilityLabel("Toolbelt")
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        appState.start()
        if appState.showsWelcome {
            SettingsWindowController.shared.show(appState)
        }
    }

    /// Opening Toolbelt again (Spotlight, Finder) shows Settings, in case the menu-bar icon is hidden.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        SettingsWindowController.shared.show(appState)
        return true
    }
}
