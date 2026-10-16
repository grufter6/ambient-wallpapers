// Ambient Wallpapers: a menu-bar app that rotates calm, dark photos as your desktop wallpaper.
// Started at login with --background; opening it yourself shows the settings window.
import AppKit

final class App: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    let w = WallpaperManager.shared
    let settingsWindow = SettingsWindow()

    func applicationDidFinishLaunching(_ n: Notification) {
        item.button?.image = NSImage(systemSymbolName: "photo.on.rectangle.angled", accessibilityDescription: "Ambient Wallpapers")
        let menu = NSMenu(); menu.delegate = self
        item.menu = menu
        if w.isOn { w.start() } else { w.refresh() }
        if !CommandLine.arguments.contains("--background") { openSettings() }
    }

    /// Opening the app again while it's running (it has no Dock icon) shows the settings window.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openSettings(); return true
    }

    func applicationWillTerminate(_ n: Notification) {
        if w.isOn { w.stop() }                // quitting puts your own wallpaper back
    }

    // Rebuilt every time the menu opens, so it always shows what's on screen now.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        w.refresh()
        if w.isOn {
            let title = w.current.map { WallpaperManager.title($0) } ?? "—"
            menu.addItem(withTitle: "Showing: \(title)", action: nil, keyEquivalent: "")
            if let t = w.nextChange {
                menu.addItem(withTitle: "Next change at \(t.formatted(date: .omitted, time: .shortened))", action: nil, keyEquivalent: "")
            }
            menu.addItem(.separator())
            add(menu, "Previous wallpaper", #selector(previous))
            add(menu, "Next wallpaper", #selector(next), key: "n")
            menu.addItem(.separator())
            add(menu, "Stop rotating (back to my own wallpaper)", #selector(toggle))
        } else {
            menu.addItem(withTitle: "Off: your own wallpaper is showing", action: nil, keyEquivalent: "")
            menu.addItem(.separator())
            add(menu, "Start rotating", #selector(toggle))
        }
        add(menu, "Photos, search and settings…", #selector(openSettings), key: ",")
        menu.addItem(.separator())
        add(menu, "Quit Ambient Wallpapers", #selector(NSApplication.terminate(_:)), key: "q", target: NSApp)
    }

    func add(_ menu: NSMenu, _ title: String, _ sel: Selector, key: String = "", target: AnyObject? = nil) {
        let mi = NSMenuItem(title: title, action: sel, keyEquivalent: key)
        mi.target = target ?? self
        menu.addItem(mi)
    }

    @objc func previous() { w.previous() }
    @objc func next() { w.next() }
    @objc func toggle() {
        var s = loadSettings(); s.ambientWallpapers = !(s.ambientWallpapers ?? true); saveSettings(s)
        settingsWindow.model.reload()
        w.apply()
    }
    @objc func openSettings() { settingsWindow.show(onChange: {}) }
}

let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
