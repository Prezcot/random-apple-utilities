import Foundation

/// Controls Night Shift through CoreBrightness, the private framework System Settings uses.
/// Apple doesn't publish this API, so it's looked up at runtime instead of linked. The method
/// names and status layout match the open-source apps Shifty and nightlight.
@MainActor
final class BlueLightClient {
    enum Mode: Int32, Sendable {
        case off = 0
        case sunsetToSunrise = 1
        case custom = 2
    }

    struct Schedule: Equatable, Codable, Sendable {
        var fromHour: Int32
        var fromMinute: Int32
        var toHour: Int32
        var toMinute: Int32
    }

    struct Status: Equatable, Sendable {
        /// Whether Night Shift is on right now.
        var isEnabled: Bool
        var mode: Mode
        var schedule: Schedule
        /// Whether this Mac and its displays support Night Shift.
        var isAvailable: Bool
    }

    private static let requiredSelectors = [
        "getBlueLightStatus:", "setEnabled:", "getStrength:", "setStrength:commit:",
        "setMode:", "setSchedule:", "setStatusNotificationBlock:",
    ]

    private let client: NSObject

    init?() {
        guard Bundle(path: "/System/Library/PrivateFrameworks/CoreBrightness.framework")?.load() == true,
              let type = NSClassFromString("CBBlueLightClient") as? NSObject.Type
        else { return nil }
        let client = type.init()
        guard Self.requiredSelectors.allSatisfy({ client.responds(to: NSSelectorFromString($0)) }) else { return nil }
        self.client = client
    }

    func status() -> Status? {
        // C layout: BOOL active, enabled, sunSchedulePermitted; int mode;
        // int fromHour, fromMinute, toHour, toMinute; unsigned long long disableFlags; BOOL available.
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: 64, alignment: 8)
        defer { buffer.deallocate() }
        buffer.initializeMemory(as: UInt8.self, repeating: 0, count: 64)

        typealias Fn = @convention(c) (AnyObject, Selector, UnsafeMutableRawPointer) -> Bool
        let (fn, sel) = method("getBlueLightStatus:", as: Fn.self)
        guard fn(client, sel, buffer) else { return nil }

        func int(_ offset: Int) -> Int32 { buffer.load(fromByteOffset: offset, as: Int32.self) }
        func bool(_ offset: Int) -> Bool { buffer.load(fromByteOffset: offset, as: UInt8.self) != 0 }
        return Status(
            isEnabled: bool(1),
            mode: Mode(rawValue: int(4)) ?? .off,
            schedule: Schedule(fromHour: int(8), fromMinute: int(12), toHour: int(16), toMinute: int(20)),
            isAvailable: bool(32)
        )
    }

    func setEnabled(_ enabled: Bool) {
        typealias Fn = @convention(c) (AnyObject, Selector, Bool) -> Bool
        let (fn, sel) = method("setEnabled:", as: Fn.self)
        _ = fn(client, sel, enabled)
    }

    /// Strength from 0 (least warm) to 1 (most warm).
    func strength() -> Float? {
        typealias Fn = @convention(c) (AnyObject, Selector, UnsafeMutablePointer<Float>) -> Bool
        let (fn, sel) = method("getStrength:", as: Fn.self)
        var value: Float = 0
        return fn(client, sel, &value) ? value : nil
    }

    /// `commit: false` previews the strength without saving it, for use while a slider is dragged.
    func setStrength(_ strength: Float, commit: Bool) {
        typealias Fn = @convention(c) (AnyObject, Selector, Float, Bool) -> Bool
        let (fn, sel) = method("setStrength:commit:", as: Fn.self)
        _ = fn(client, sel, strength, commit)
    }

    func setMode(_ mode: Mode) {
        typealias Fn = @convention(c) (AnyObject, Selector, Int32) -> Bool
        let (fn, sel) = method("setMode:", as: Fn.self)
        _ = fn(client, sel, mode.rawValue)
    }

    func setSchedule(_ schedule: Schedule) {
        typealias Fn = @convention(c) (AnyObject, Selector, UnsafeMutableRawPointer) -> Bool
        let (fn, sel) = method("setSchedule:", as: Fn.self)
        var raw = (schedule.fromHour, schedule.fromMinute, schedule.toHour, schedule.toMinute)
        _ = withUnsafeMutableBytes(of: &raw) { fn(client, sel, $0.baseAddress!) }
    }

    /// Calls `handler` on a background queue whenever Night Shift changes, from Toolbelt or anywhere else.
    func onStatusChange(_ handler: @escaping @Sendable () -> Void) {
        typealias Block = @Sendable @convention(block) () -> Void
        // @escaping: CoreBrightness keeps the block, and Swift traps if a non-escaping one is retained.
        typealias Fn = @convention(c) (AnyObject, Selector, @escaping Block) -> Void
        let (fn, sel) = method("setStatusNotificationBlock:", as: Fn.self)
        fn(client, sel, handler)
    }

    private func method<F>(_ name: String, as type: F.Type) -> (F, Selector) {
        let sel = NSSelectorFromString(name)
        return (unsafeBitCast(client.method(for: sel), to: type), sel)
    }
}
