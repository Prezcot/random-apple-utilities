import AppKit
import SwiftUI

/// Keeps Night Shift on until you turn it off.
///
/// On: Apple's schedule is set to end 11 to 12 hours from now and moved on every hour, so its end
/// never comes while Toolbelt runs. A watcher turns Night Shift straight back on whenever macOS
/// switches it off. After Toolbelt quits, Night Shift stays on until the schedule ends.
/// Off: Night Shift is turned off and Apple's schedule set to Off, so macOS can't turn it back on.
/// Turning the module off in Settings restores the Night Shift setup you had before.
@MainActor
@Observable
final class NightShiftModule: ToolbeltModule {
    let id = "night-shift-forever"
    let name = "Night Shift Forever"
    let summary = "Keeps Night Shift on until you turn it off. No permissions needed."
    let symbolName = "moon.fill"

    let isSupported: Bool
    private(set) var isOn: Bool
    /// 0 (least warm) to 1 (most warm).
    private(set) var strength: Double
    /// True while the slider is temporarily showing warmth with Night Shift off.
    private(set) var isPreviewing = false

    @ObservationIgnored private let client: BlueLightClient?
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var isActive = false
    @ObservationIgnored private var isDragging = false
    @ObservationIgnored private var lastApplied = Date.distantPast
    @ObservationIgnored private var previewEnd: Task<Void, Never>?
    @ObservationIgnored private var heartbeat: Timer?
    @ObservationIgnored private var wakeObserver: NSObjectProtocol?

    /// Apple's schedule can't span a full 24 hours, and Night Shift fades out over the 2 minutes
    /// before it ends while still reporting itself on, so the watcher can't catch it. Instead the
    /// schedule's end is kept 11 to 12 hours away: it runs from 1 minute past an hour to that hour.
    private static func rollingSchedule(at date: Date) -> BlueLightClient.Schedule {
        let endHour = Int32((Calendar.current.component(.hour, from: date) + 12) % 24)
        return BlueLightClient.Schedule(fromHour: endHour, fromMinute: 1, toHour: endHour, toMinute: 0)
    }

    private enum Keys {
        static let isOn = "nightShift.isOn"
        static let strength = "nightShift.strength"
        static let snapshot = "nightShift.snapshot"
    }

    /// The Night Shift setup from before the module was turned on.
    private struct Snapshot: Codable {
        var isEnabled: Bool
        var mode: Int32
        var schedule: BlueLightClient.Schedule
        var strength: Float
    }

    init(client: BlueLightClient? = BlueLightClient(), defaults: UserDefaults = .standard) {
        self.client = client
        self.defaults = defaults
        isSupported = client?.status()?.isAvailable ?? false
        isOn = defaults.object(forKey: Keys.isOn) as? Bool ?? true
        strength = defaults.object(forKey: Keys.strength) as? Double ?? Double(client?.strength() ?? 0.5)
    }

    func makePanel() -> AnyView {
        AnyView(NightShiftPanel(module: self))
    }

    // MARK: Lifecycle

    func activate() {
        guard let client, isSupported, !isActive else { return }
        isActive = true
        if defaults.data(forKey: Keys.snapshot) == nil { saveSnapshot() }

        client.onStatusChange { [weak self] in
            Task { @MainActor in self?.reconcile() }
        }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.reconcile() }
        }
        heartbeat = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.reconcile() }
        }

        client.setStrength(Float(strength), commit: true)
        apply()
    }

    func deactivate() {
        guard let client, isActive else { return }
        isActive = false
        client.onStatusChange {}
        heartbeat?.invalidate()
        heartbeat = nil
        if let wakeObserver { NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver) }
        wakeObserver = nil
        previewEnd?.cancel()
        isPreviewing = false
        restoreSnapshot()
    }

    // MARK: Controls

    func toggle() {
        isOn.toggle()
        defaults.set(isOn, forKey: Keys.isOn)
        previewEnd?.cancel()
        isPreviewing = false
        apply()
    }

    /// Called continuously while the slider is dragged. With Night Shift off, it switches on
    /// temporarily so you can see the warmth before committing.
    func previewStrength(_ value: Double) {
        isDragging = true
        previewEnd?.cancel()
        strength = value
        client?.setStrength(Float(value), commit: false)
        if !isOn && !isPreviewing {
            isPreviewing = true
            client?.setEnabled(true)
        }
    }

    /// Called when the slider is released.
    func commitStrength() {
        isDragging = false
        client?.setStrength(Float(strength), commit: true)
        defaults.set(strength, forKey: Keys.strength)
        guard isPreviewing else { return }
        previewEnd = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled, let self else { return }
            isPreviewing = false
            apply()
        }
    }

    // MARK: Keeping Night Shift where Toolbelt wants it

    private func apply() {
        guard let client, isActive, !isPreviewing else { return }
        lastApplied = .now
        if isOn {
            client.setSchedule(Self.rollingSchedule(at: .now))
            client.setMode(.custom)
            client.setEnabled(true)
        } else {
            client.setEnabled(false)
            client.setMode(.off)
        }
    }

    /// Runs whenever Night Shift changes, on wake, and every 30 seconds.
    /// Toolbelt wins on on/off and the schedule; a warmth change made elsewhere is adopted by the slider.
    private func reconcile() {
        guard let client, isActive, !isPreviewing, let status = client.status() else { return }

        let wantedMode: BlueLightClient.Mode = isOn ? .custom : .off
        let isAsWanted = status.isEnabled == isOn && status.mode == wantedMode
            && (!isOn || status.schedule == Self.rollingSchedule(at: .now))
        // The rate limit stops Toolbelt fighting macOS in a tight loop if a change doesn't stick.
        if !isAsWanted, Date.now.timeIntervalSince(lastApplied) > 2 {
            apply()
        }

        if !isDragging, let system = client.strength(), abs(Double(system) - strength) > 0.01 {
            strength = Double(system)
            defaults.set(strength, forKey: Keys.strength)
        }
    }

    private func saveSnapshot() {
        guard let client, let status = client.status() else { return }
        let snapshot = Snapshot(
            isEnabled: status.isEnabled,
            mode: status.mode.rawValue,
            schedule: status.schedule,
            strength: client.strength() ?? Float(strength)
        )
        defaults.set(try? JSONEncoder().encode(snapshot), forKey: Keys.snapshot)
    }

    private func restoreSnapshot() {
        guard let client,
              let data = defaults.data(forKey: Keys.snapshot),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data)
        else { return }
        client.setSchedule(snapshot.schedule)
        client.setMode(BlueLightClient.Mode(rawValue: snapshot.mode) ?? .off)
        client.setStrength(snapshot.strength, commit: true)
        client.setEnabled(snapshot.isEnabled)
        defaults.removeObject(forKey: Keys.snapshot)
    }
}
