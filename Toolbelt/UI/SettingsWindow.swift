import AppKit
import ServiceManagement
import SwiftUI

/// Toolbelt has no Dock icon, so Settings is a plain AppKit window brought to the front by hand.
/// While it's open Toolbelt becomes a regular app (briefly showing in the Dock) so the window can take focus.
@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private var window: NSWindow?
    private weak var appState: AppState?

    func show(_ appState: AppState) {
        self.appState = appState
        appState.launchAtLogin.refresh()
        if window == nil {
            let hosting = NSHostingController(rootView: SettingsView().environment(appState))
            let window = NSWindow(contentViewController: hosting)
            window.title = "Toolbelt Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.delegate = self
            // Size to the SwiftUI content first, or center() places a zero-size window.
            window.setContentSize(hosting.view.fittingSize)
            window.center()
            self.window = window
        }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        appState?.showsWelcome = false
        NSApp.setActivationPolicy(.accessory)
    }
}

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if appState.showsWelcome {
                WelcomeHeader()
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Modules")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                    ForEach(appState.modules, id: \.id) { module in
                        ModuleCard(module: module)
                    }
                }
            }
            LaunchAtLoginRow()
        }
        .padding(24)
        .frame(width: 540)
    }
}

private struct WelcomeHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 26))
                .foregroundStyle(.black)
                .frame(width: 56, height: 56)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.orange))
            Text("Welcome to Toolbelt")
                .font(.title2.weight(.semibold))
            Text("Small Mac utilities in one menu-bar icon. Turn on what you want below.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }
}

/// A module's card in Settings. Clicking the card turns the module on or off.
private struct ModuleCard: View {
    @Environment(AppState.self) private var appState
    let module: any ToolbeltModule

    var body: some View {
        let isOn = appState.isEnabled(module)
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        Button {
            appState.setEnabled(!isOn, for: module)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: module.symbolName)
                        .font(.system(size: 15))
                        .foregroundStyle(.black)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(.orange))
                    Spacer()
                    Text(isOn ? "On" : "Off")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isOn ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
                }
                Text(module.name)
                    .font(.system(size: 14, weight: .semibold))
                Text(module.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if !module.permissions.isEmpty {
                    Text("Needs " + module.permissions.map(\.name).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(shape.fill(Color.primary.opacity(0.06)))
            .overlay(shape.strokeBorder(isOn ? Color.orange : Color.primary.opacity(0.2), lineWidth: 1.5))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

private struct LaunchAtLoginRow: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let launchAtLogin = appState.launchAtLogin
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Launch at login")
                Text(launchAtLogin.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if launchAtLogin.status == .requiresApproval {
                Button("Open Login Items", action: launchAtLogin.openLoginItems)
            }
            Toggle("Launch at login", isOn: Binding(
                get: { launchAtLogin.isEnabled },
                set: { launchAtLogin.setEnabled($0) }
            ))
            .toggleStyle(.switch)
            .tint(.orange)
            .labelsHidden()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.06)))
    }
}
