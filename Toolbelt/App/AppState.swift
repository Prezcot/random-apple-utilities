import Foundation
import Observation

/// App-wide state: which modules exist, which are turned on, and which tab the panel shows.
@MainActor
@Observable
final class AppState {
    let modules: [any ToolbeltModule]
    let launchAtLogin = LaunchAtLogin()
    var selectedModuleID: String?
    /// True on the very first launch, until the Settings window is closed.
    var showsWelcome: Bool

    private(set) var enabledModuleIDs: Set<String>
    @ObservationIgnored private let defaults: UserDefaults

    private enum Keys {
        static let enabledModules = "enabledModules"
        static let hasLaunched = "hasLaunched"
    }

    init(modules: [any ToolbeltModule] = ModuleRegistry.makeAll(), defaults: UserDefaults = .standard) {
        self.modules = modules
        self.defaults = defaults
        enabledModuleIDs = Set(defaults.stringArray(forKey: Keys.enabledModules) ?? [])
        showsWelcome = !defaults.bool(forKey: Keys.hasLaunched)
    }

    var enabledModules: [any ToolbeltModule] {
        modules.filter { enabledModuleIDs.contains($0.id) }
    }

    /// The module whose controls the panel shows.
    var selectedModule: (any ToolbeltModule)? {
        enabledModules.first { $0.id == selectedModuleID } ?? enabledModules.first
    }

    var menuBarSymbol: String {
        enabledModules.first?.menuBarSymbol ?? "wrench.and.screwdriver"
    }

    func start() {
        if showsWelcome {
            defaults.set(true, forKey: Keys.hasLaunched)
            launchAtLogin.setEnabled(true)
        }
        enabledModules.forEach { $0.activate() }
    }

    func isEnabled(_ module: any ToolbeltModule) -> Bool {
        enabledModuleIDs.contains(module.id)
    }

    func setEnabled(_ enabled: Bool, for module: any ToolbeltModule) {
        guard enabled != isEnabled(module) else { return }
        if enabled {
            module.permissions.filter { !$0.isGranted }.forEach { $0.request() }
            enabledModuleIDs.insert(module.id)
            module.activate()
        } else {
            enabledModuleIDs.remove(module.id)
            module.deactivate()
        }
        defaults.set(Array(enabledModuleIDs), forKey: Keys.enabledModules)
    }
}
