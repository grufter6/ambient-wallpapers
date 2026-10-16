#!/bin/bash
# Builds build/Ambient Wallpapers.app
set -euo pipefail
cd "$(dirname "$0")"
rm -rf build && mkdir -p build
APP="build/Ambient Wallpapers.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O -o "$APP/Contents/MacOS/AmbientWallpapers" src/*.swift
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Ambient Wallpapers</string>
  <key>CFBundleDisplayName</key><string>Ambient Wallpapers</string>
  <key>CFBundleIdentifier</key><string>com.ambientwallpapers.app</string>
  <key>CFBundleExecutable</key><string>AmbientWallpapers</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP" >/dev/null 2>&1
echo "Built $APP"
