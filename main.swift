import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?

    private let totalItem = NSMenuItem(title: "Total: —", action: nil, keyEquivalent: "")
    private let usedItem = NSMenuItem(title: "Used: —", action: nil, keyEquivalent: "")
    private let freeItem = NSMenuItem(title: "Available: —", action: nil, keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let menu = NSMenu()
        menu.addItem(totalItem)
        menu.addItem(usedItem)
        menu.addItem(freeItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Refresh Now", action: #selector(refresh), keyEquivalent: "r").target = self
        menu.addItem(withTitle: "Open Storage Settings…", action: #selector(openStorageSettings), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit StorageBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu

        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    @objc private func refresh() {
        let url = URL(fileURLWithPath: "/")
        guard let values = try? url.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
        ]),
        let total = values.volumeTotalCapacity,
        let available = values.volumeAvailableCapacityForImportantUsage else {
            statusItem.button?.title = "💾 n/a"
            return
        }

        let used = Int64(total) - available
        let percentUsed = Int((Double(used) / Double(total) * 100).rounded())

        let fmt = ByteCountFormatter()
        fmt.countStyle = .file

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "internaldrive", accessibilityDescription: "Storage")
            button.imagePosition = .imageLeading
            button.title = " \(fmt.string(fromByteCount: available)) / \(fmt.string(fromByteCount: Int64(total)))"
        }

        totalItem.title = "Total: \(fmt.string(fromByteCount: Int64(total)))"
        usedItem.title = "Used: \(fmt.string(fromByteCount: used)) (\(percentUsed)%)"
        freeItem.title = "Available: \(fmt.string(fromByteCount: available))"
    }

    @objc private func openStorageSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.settings.Storage")!)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
