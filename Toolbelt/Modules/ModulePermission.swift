import ApplicationServices

/// A macOS permission a module needs. Add cases here as modules need them.
enum ModulePermission: Hashable, Sendable {
    case accessibility

    var name: String {
        switch self {
        case .accessibility: "Accessibility"
        }
    }

    @MainActor
    var isGranted: Bool {
        switch self {
        case .accessibility: AXIsProcessTrusted()
        }
    }

    /// Shows the system prompt that sends the user to System Settings › Privacy & Security.
    @MainActor
    func request() {
        switch self {
        case .accessibility:
            AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        }
    }
}
