import SwiftUI

/// What opens when you click the menu-bar icon: module tabs (only with 2+ modules on),
/// the selected module's controls, and a footer with Settings and Quit.
struct PanelView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 10) {
            if appState.enabledModules.count > 1 {
                ModuleTabs()
            }
            if let module = appState.selectedModule {
                module.makePanel()
            } else {
                EmptyPanel()
            }
            PanelFooter()
        }
        .padding(12)
        .frame(width: 320)
    }
}

private struct ModuleTabs: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 6) {
            ForEach(appState.enabledModules, id: \.id) { module in
                let isSelected = module.id == appState.selectedModule?.id
                Button {
                    appState.selectedModuleID = module.id
                } label: {
                    Image(systemName: module.symbolName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isSelected ? AnyShapeStyle(.background) : AnyShapeStyle(.primary))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(isSelected ? Color.primary : Color.primary.opacity(0.1)))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help(module.name)
                .accessibilityLabel(module.name)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
            Text(appState.selectedModule?.name ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 6)
            Spacer(minLength: 0)
        }
    }
}

private struct EmptyPanel: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 8) {
            Text("No modules turned on")
                .font(.system(size: 14, weight: .semibold))
            Text("Pick the modules you want in Settings. Their tiles will show up here.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                SettingsWindowController.shared.show(appState)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .tile()
    }
}

private struct PanelFooter: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 6) {
            Text("Toolbelt")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            CircleIconButton(symbol: "slider.horizontal.3", label: "Settings") {
                SettingsWindowController.shared.show(appState)
            }
            .keyboardShortcut(",", modifiers: .command)
            CircleIconButton(symbol: "power", label: "Quit Toolbelt") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(.horizontal, 2)
    }
}
