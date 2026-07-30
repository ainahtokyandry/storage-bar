// The storage section: free space on the boot volume.
//
// Compiled two ways, from the same source — into MacBar alongside the other
// sections, or into StorageBar.app on its own. Both builds supply the host that
// defines BarSection; see build.sh.

import AppKit
import Foundation

final class StorageSection: NSObject, BarSection {
    let name = "Storage"
    let showKey = "showStorage"

    private var onUpdate: () -> Void = {}
    private var timer: Timer?

    private var total: Int64 = 0
    private var available: Int64 = 0
    private var readable = false

    private static let bytes: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .file      // base 1000, matching Finder
        return f
    }()

    func activate(onUpdate: @escaping () -> Void) {
        self.onUpdate = onUpdate
        read()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.read()
        }
    }

    func refresh(force: Bool) { read() }

    /// volumeAvailableCapacityForImportantUsage is the measure Finder uses, so
    /// the number accounts for purgeable space and matches what macOS reports
    /// elsewhere.
    private func read() {
        let url = URL(fileURLWithPath: "/")
        if let values = try? url.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
        ]),
            let capacity = values.volumeTotalCapacity,
            let free = values.volumeAvailableCapacityForImportantUsage {
            total = Int64(capacity)
            available = free
            readable = true
        } else {
            readable = false
        }
        onUpdate()
    }

    private var used: Int64 { total - available }

    private var percentUsed: Int {
        total > 0 ? Int((Double(used) / Double(total) * 100).rounded()) : 0
    }

    private var freeFraction: Double {
        guard readable, total > 0 else { return 1 }
        return Double(available) / Double(total)
    }

    private var low: Bool { freeFraction < 0.10 }

    /// The same idea as a usage limit: no colour until it matters.
    private var color: NSColor {
        if freeFraction < 0.05 { return Palette.critical }
        if freeFraction < 0.10 { return Palette.warning }
        return .labelColor
    }

    func titleSegments(compact: Bool) -> [Segment] {
        guard readable else { return [.value("n/a")] }
        var segments: [Segment] = [.value(Self.bytes.string(fromByteCount: available), color: color)]
        if !compact {
            segments.append(.label(" / \(Self.bytes.string(fromByteCount: total))"))
        }
        return segments
    }

    func menuRows() -> [NSMenuItem] {
        guard readable else {
            return [MenuKit.alert("Could not read the boot volume")]
        }
        let free = "Available:  \(Self.bytes.string(fromByteCount: available))"
        return [
            low ? MenuKit.alert(free, color: color) : MenuKit.note(free, color: .labelColor),
            MenuKit.note("Used:       \(Self.bytes.string(fromByteCount: used)) (\(percentUsed)%)"),
            MenuKit.note("Total:      \(Self.bytes.string(fromByteCount: total))"),
            MenuKit.action("Open Storage Settings…", #selector(openSettings), target: self),
        ]
    }

    func snapshot(_ completion: @escaping ([String], Bool) -> Void) {
        read()
        guard readable else {
            completion(["could not read the boot volume"], false)
            return
        }
        completion([
            "Available:  \(Self.bytes.string(fromByteCount: available))",
            "Used:       \(Self.bytes.string(fromByteCount: used)) (\(percentUsed)%)",
            "Total:      \(Self.bytes.string(fromByteCount: total))",
        ], true)
    }

    @objc private func openSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.settings.Storage")!)
    }
}
