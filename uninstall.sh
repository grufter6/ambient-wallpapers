#!/bin/bash
# Removes Ambient Wallpapers and puts your own wallpaper back. Your photos stay in
# ~/Library/Application Support/Ambient Wallpapers until you delete that folder.
osascript -e 'quit app "Ambient Wallpapers"' 2>/dev/null; sleep 1     # a normal quit puts your own wallpaper back
launchctl bootout "gui/$(id -u)/com.ambientwallpapers.app" 2>/dev/null
rm -f "$HOME/Library/LaunchAgents/com.ambientwallpapers.app.plist"
rm -rf "$HOME/Applications/Ambient Wallpapers.app"
echo "Ambient Wallpapers removed."
