// Ambient Wallpapers: settings and data live in ~/Library/Application Support/Ambient Wallpapers
// (or $AMBIENT_DIR, for tests). The Wallpapers folder in there holds the photos that rotate.
import Foundation

struct Settings: Codable, Equatable {
    var ambientWallpapers: Bool? = true    // rotating; off puts your own wallpaper back
    var wallpaperMinutes: Int? = 60
    var wallpaperShuffle: Bool? = true     // random order (false: in order)
    var wallpaperOff: [String]? = []       // file names left out of the rotation
}

let dir: URL = {
    if let d = ProcessInfo.processInfo.environment["AMBIENT_DIR"] { return URL(fileURLWithPath: d) }
    return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Ambient Wallpapers")
}()
let settingsURL = dir.appendingPathComponent("settings.json")

func loadSettings() -> Settings {
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    if let data = try? Data(contentsOf: settingsURL), let s = try? JSONDecoder().decode(Settings.self, from: data) { return s }
    saveSettings(Settings())
    return Settings()
}

func saveSettings(_ s: Settings) {
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted, .sortedKeys]
    try? enc.encode(s).write(to: settingsURL, options: .atomic)
}
