// The settings window: everything about the wallpapers, plus searching for more photos.
import AppKit
import SwiftUI

final class SettingsModel: ObservableObject {
    @Published var draft = loadSettings()

    func reload() { draft = loadSettings() }

    /// Every change applies and saves right away.
    func setWallpaper(_ change: (inout Settings) -> Void) {
        var disk = loadSettings(); change(&disk); saveSettings(disk)
        change(&draft)
        WallpaperManager.shared.apply()
        onChange()
    }
    var onChange: () -> Void = {}

    func addWallpapers() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        panel.prompt = "Add"
        panel.message = "Pick photos to add to your wallpapers. Darker, calm photos work best."
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK else { return }
        WallpaperManager.shared.add(panel.urls)
        WallpaperManager.shared.apply()
    }
}

final class SettingsWindow {
    let model = SettingsModel()
    var window: NSWindow?

    func show(onChange: @escaping () -> Void) {
        if window?.isVisible != true { model.reload() }
        WallpaperManager.shared.refresh()
        model.onChange = onChange
        if window == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 620, height: 700),
                             styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
            w.title = "Ambient Wallpapers"
            w.isReleasedWhenClosed = false
            w.contentView = NSHostingView(rootView: ScrollView { WallpaperSection(m: model).padding(24) }.frame(minWidth: 620, minHeight: 500))
            w.setContentSize(NSSize(width: 620, height: 700))
            w.center()
            window = w
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        // For checking the layout without screen-recording permission: AMBIENT_SNAPSHOT=/path/shot.png
        if let path = ProcessInfo.processInfo.environment["AMBIENT_SNAPSHOT"] {
            let delay = Double(ProcessInfo.processInfo.environment["AMBIENT_SNAPSHOT_DELAY"] ?? "") ?? 1.5
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let v = self?.window?.contentView, let rep = v.bitmapImageRepForCachingDisplay(in: v.bounds) else { return }
                v.cacheDisplay(in: v.bounds, to: rep)
                try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
            }
        }
    }
}

// MARK: - wallpapers section

struct WallpaperSection: View {
    @ObservedObject var m: SettingsModel
    @ObservedObject var w = WallpaperManager.shared
    @State private var kind: WallpaperKind = .all
    // AMBIENT_SNAPSHOT_SEARCH="query" opens on search results, for checking the layout
    @State private var finding = ProcessInfo.processInfo.environment["AMBIENT_SNAPSHOT_SEARCH"] != nil

    var on: Bool { m.draft.ambientWallpapers ?? true }
    var off: Set<String> { Set(m.draft.wallpaperOff ?? []) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ambient Wallpapers").font(.title3.bold())
                Text("Calm photos that change by themselves. Changes here apply right away.").font(.callout).foregroundStyle(.secondary)
            }
            Toggle("Rotate my wallpaper through these photos", isOn: Binding(
                get: { on }, set: { v in m.setWallpaper { $0.ambientWallpapers = v } }))
            if on {
                HStack(spacing: 16) {
                    Picker("Change", selection: Binding(
                        get: { m.draft.wallpaperMinutes ?? 60 }, set: { v in m.setWallpaper { $0.wallpaperMinutes = v } })) {
                        ForEach(wallpaperIntervals, id: \.minutes) { Text($0.label).tag($0.minutes) }
                    }
                    .fixedSize()
                    Picker("Order", selection: Binding(
                        get: { m.draft.wallpaperShuffle ?? true }, set: { v in m.setWallpaper { $0.wallpaperShuffle = v } })) {
                        Text("Shuffle").tag(true); Text("In order").tag(false)
                    }
                    .pickerStyle(.segmented).fixedSize()
                }
                HStack {
                    Button { w.previous() } label: { Label("Previous", systemImage: "chevron.left") }
                    Button { w.next() } label: { Label("Next", systemImage: "chevron.right") }
                    Spacer()
                    Button { m.addWallpapers() } label: { Label("Add photos…", systemImage: "plus") }
                    Button { NSWorkspace.shared.open(w.folder) } label: { Image(systemName: "folder") }.help("Show the wallpaper folder in Finder")
                }
                Text(status).font(.callout).foregroundStyle(.secondary)
                Picker("Mode", selection: $finding) {
                    Text("Your wallpapers").tag(false)
                    Text("Search for more photos").tag(true)
                }
                .pickerStyle(.segmented).labelsHidden().fixedSize()
                .padding(.top, 6)
                if finding {
                    WallpaperSearchView()
                } else {
                Picker("Show", selection: $kind) {
                    ForEach(WallpaperKind.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented).labelsHidden()
                let shown = w.all.filter { kind == .all || WallpaperKind.of($0) == kind }
                if shown.isEmpty {
                    Text(kind == .mine ? "No photos of your own yet. Search for some, or click Add photos… to use your own files." : "No photos here.")
                        .foregroundStyle(.secondary).padding(.vertical, 8)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 12) {
                    ForEach(shown, id: \.self) { u in tile(u) }
                }
                Text("Click a photo to show it now. Untick photos to leave them out of the rotation.")
                    .font(.callout).foregroundStyle(.secondary)
                }
            } else {
                Text("Your own wallpaper is showing. Turn this on to rotate the focus photos.").foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var status: String {
        let n = w.all.filter { !off.contains($0.lastPathComponent) }.count
        var parts = ["\(n) of \(w.all.count) photos in the rotation"]
        if let c = w.current { parts.append("showing \(WallpaperManager.title(c))") }
        if let t = w.nextChange { parts.append("next change at \(t.formatted(date: .omitted, time: .shortened))") }
        return parts.joined(separator: " · ")
    }

    func tile(_ u: URL) -> some View {
        let included = !off.contains(u.lastPathComponent)
        let isCurrent = u == w.current
        return VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let img = w.thumbnail(u) { Image(nsImage: img).resizable().aspectRatio(contentMode: .fill) }
                    else { Color.gray.opacity(0.2) }
                }
                .frame(height: 80).frame(maxWidth: .infinity).clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isCurrent ? Color.accentColor : .clear, lineWidth: 3))
                .opacity(included ? 1 : 0.35)
                .contentShape(Rectangle())
                .onTapGesture { w.show(u) }
                Button { toggle(u) } label: {
                    Image(systemName: included ? "checkmark.circle.fill" : "circle")
                        .font(.title3).foregroundStyle(included ? Color.accentColor : .white)
                        .background(Circle().fill(.black.opacity(0.35)))
                }
                .buttonStyle(.plain).padding(5)
                .help(included ? "Leave out of the rotation" : "Put back in the rotation")
                if isCurrent {
                    Text("Now").font(.caption2.bold()).padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.accentColor, in: Capsule()).foregroundStyle(.white)
                        .padding(6).frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            Text(WallpaperManager.title(u)).font(.caption).lineLimit(1).foregroundStyle(included ? .primary : .secondary)
        }
        .contextMenu {
            Button("Show now") { w.show(u) }
            Button(included ? "Leave out of the rotation" : "Put back in the rotation") { toggle(u) }
            if WallpaperKind.of(u) == .mine {
                Button("Move to Trash") { w.trash(u); m.setWallpaper { $0.wallpaperOff?.removeAll { $0 == u.lastPathComponent } } }
            }
        }
    }

    func toggle(_ u: URL) {
        m.setWallpaper { s in
            var o = Set(s.wallpaperOff ?? [])
            if o.contains(u.lastPathComponent) { o.remove(u.lastPathComponent) } else { o.insert(u.lastPathComponent) }
            s.wallpaperOff = o.sorted()
        }
    }
}
