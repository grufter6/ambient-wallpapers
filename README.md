# Ambient Wallpapers

A Mac menu-bar app that rotates calm, dark photos as your desktop wallpaper.

- **Menu bar (photo icon):** what's showing, Previous / Next, stop or start rotating, Quit.
- **Settings window** (menu → Photos, search and settings…, or open the app):
  - change every 15 minutes up to once a day, shuffle or in order
  - click a photo to show it now, untick photos to leave them out
  - **Search for more photos:** free Creative Commons photos from Openverse; **+ Add** fits the photo to your
    screen, dims it if it's bright, and credits it in `MY-CREDITS.txt`
  - **Add photos…** for your own files
- Stopping or quitting puts your own wallpaper back.

Includes 26 photos from Wikimedia Commons (night skies, nature, city skylines). `wallpapers/CREDITS.txt` holds the
attribution their licences require, so keep it with them.

## Install
`./install.sh` builds the app, puts it in `~/Applications`, copies the photos to
`~/Library/Application Support/Ambient Wallpapers/Wallpapers` and starts it at login. No password needed.
`./uninstall.sh` removes it and puts your own wallpaper back.
