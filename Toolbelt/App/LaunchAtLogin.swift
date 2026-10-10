import Foundation
import Observation
import ServiceManagement

/// Wraps macOS's login-item registration. The status is read back from the system,
/// so it stays correct if you change it in System Settings › General › Login Items.
@MainActor
@Observable
final class LaunchAtLogin {
    private(set) var status = SMAppService.mainApp.status

    var isEnabled: Bool {
        status == .enabled || status == .requiresApproval
    }

    var statusText: String {
        switch status {
        case .enabled: "On · listed in System Settings › General › Login Items"
        case .requiresApproval: "Waiting for your approval in Login Items"
        case .notFound: "Unavailable · move Toolbelt to Applications"
        default: "Off"
        }
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Toolbelt: couldn't change launch at login: \(error)")
        }
        refresh()
    }

    func refresh() {
        status = SMAppService.mainApp.status
    }

    func openLoginItems() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
