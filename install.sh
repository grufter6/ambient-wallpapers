#!/bin/bash
# Installs Ambient Wallpapers for this user: the app in ~/Applications, the photos, and a login item.
# No password needed. Safe to run again to update; your own photos and settings are kept.
set -euo pipefail
cd "$(dirname "$0")"
./build.sh

DATA="$HOME/Library/Application Support/Ambient Wallpapers"
APP="$HOME/Applications/Ambient Wallpapers.app"
AGENT="$HOME/Library/LaunchAgents/com.ambientwallpapers.app.plist"
OLD="$HOME/Library/Application Support/FocusLock"      # the wallpapers used to live in Focus Lock
mkdir -p "$DATA/Wallpapers" "$HOME/Applications" "$HOME/Library/LaunchAgents"

# ── move things over from Focus Lock (once) ──
if [ -d "$OLD/Wallpapers" ] && [ ! -f "$DATA/.migrated" ]; then
  cp -n "$OLD/Wallpapers/"*.jpg "$OLD/Wallpapers/"*.jpeg "$OLD/Wallpapers/"*.png "$OLD/Wallpapers/"*.heic "$DATA/Wallpapers/" 2>/dev/null || true
  [ -f "$OLD/Wallpapers/MY-CREDITS.txt" ] && cp -n "$OLD/Wallpapers/MY-CREDITS.txt" "$DATA/Wallpapers/"
  # your wallpaper from before any rotation, so "stop rotating" can put it back
  [ -f "$OLD/original-wallpapers.json" ] && mv "$OLD/original-wallpapers.json" "$DATA/"
  if [ -f "$OLD/settings.json" ] && [ ! -f "$DATA/settings.json" ]; then
    /usr/bin/python3 - "$OLD/settings.json" "$DATA/settings.json" <<'PY' || true
import json, sys
old = json.load(open(sys.argv[1]))
keys = ("ambientWallpapers", "wallpaperMinutes", "wallpaperShuffle", "wallpaperOff")
json.dump({k: old[k] for k in keys if k in old}, open(sys.argv[2], "w"), indent=2, sort_keys=True)
PY
  fi
  touch "$DATA/.migrated"
fi

# ── the included photos (CREDITS.txt holds the attribution their licences require) ──
cp wallpapers/*.jpg wallpapers/CREDITS.txt "$DATA/Wallpapers/"

# ── the app and its login item ──
launchctl bootout "gui/$(id -u)/com.ambientwallpapers.app" 2>/dev/null || true
rm -rf "$APP"
cp -R "build/Ambient Wallpapers.app" "$APP"
cat > "$AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.ambientwallpapers.app</string>
  <key>ProgramArguments</key><array><string>$APP/Contents/MacOS/AmbientWallpapers</string><string>--background</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><dict><key>SuccessfulExit</key><false/></dict>
  <key>LimitLoadToSessionType</key><string>Aqua</string>
</dict></plist>
PLIST
launchctl bootstrap "gui/$(id -u)" "$AGENT"
sleep 2
pgrep -x AmbientWallpapers >/dev/null && echo "Installed. Look for the photo icon in the menu bar." || { echo "It didn't start." >&2; exit 1; }
