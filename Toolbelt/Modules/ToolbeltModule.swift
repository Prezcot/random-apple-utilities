import SwiftUI

/// What every module provides. To add a module, create a folder under Modules/,
/// write a class that conforms to this, and add it to `ModuleRegistry.makeAll()`.
@MainActor
protocol ToolbeltModule: AnyObject {
    /// Stable identifier, used to remember whether the module is turned on.
    var id: String { get }
    var name: String { get }
    /// One line shown on the module's card in Settings.
    var summary: String { get }
    /// SF Symbol for the module's tab and Settings card.
    var symbolName: String { get }
    /// Permissions Toolbelt asks for when the module is turned on.
    var permissions: [ModulePermission] { get }

    /// Called when the module is turned on in Settings, and at launch if it was left on.
    func activate()
    /// Called when the module is turned off in Settings.
    func deactivate()
    /// The module's controls in the menu-bar panel.
    func makePanel() -> AnyView
}

extension ToolbeltModule {
    var permissions: [ModulePermission] { [] }
}

@MainActor
enum ModuleRegistry {
    static func makeAll() -> [any ToolbeltModule] {
        [NightShiftModule()]
    }
}
