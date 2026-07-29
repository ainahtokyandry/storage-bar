# StorageBar

A tiny macOS menu bar app that keeps your startup disk's free space visible at all times.

StorageBar sits in the menu bar and shows the available and total capacity of the boot volume
in the form `free / total`, for example:

```
142.5 GB / 494.4 GB
```

Clicking the menu bar item opens a small menu with a fuller breakdown:

- **Total** - total capacity of the volume mounted at `/`
- **Used** - used space, with the percentage of the disk consumed
- **Available** - free space
- **Refresh Now** - force an immediate update (shortcut: `r` while the menu is open)
- **Open Storage Settings...** - jump straight to the Storage pane in System Settings
- **Quit StorageBar**

### Details

- Free space is read via `volumeAvailableCapacityForImportantUsage`, the same measure Finder
  uses, so the number accounts for purgeable space and matches what macOS reports elsewhere.
- The reading refreshes automatically every 60 seconds.
- The app runs as an accessory (`LSUIElement`), so it has no Dock icon and no application
  window - only the menu bar item.
- Sizes are formatted with `ByteCountFormatter` in file style (base 1000, matching Finder).
- Written in Swift against AppKit, in a single source file (`main.swift`). No third-party
  dependencies.

## Requirements

- macOS 13 or later
- Xcode Command Line Tools (provides `swiftc` and `codesign`)

If the command line tools are not installed yet:

```bash
xcode-select --install
```

## Installation

The repository ships the source, not a prebuilt binary, so the app bundle is assembled locally.

### 1. Get the source

```bash
git clone <repository-url> StorageBar
cd StorageBar
```

### 2. Build the app bundle

```bash
mkdir -p StorageBar.app/Contents/MacOS
cp Info.plist StorageBar.app/Contents/Info.plist
swiftc -O main.swift -o StorageBar.app/Contents/MacOS/StorageBar
codesign --force --sign - StorageBar.app
```

The `codesign` step signs the bundle ad hoc. It is required - an unsigned bundle will not
launch on recent versions of macOS.

### 3. Run it

```bash
open StorageBar.app
```

The reading appears in the menu bar immediately. Nothing else opens, since the app has no
window and no Dock icon.

### 4. Install it for everyday use (optional)

Move the bundle into your Applications folder so it lives outside the checkout:

```bash
mv StorageBar.app /Applications/
open /Applications/StorageBar.app
```

### 5. Launch at login (optional)

Open **System Settings > General > Login Items & Extensions**, then under
**Open at Login** press `+` and pick `StorageBar.app`.

## Rebuilding after a change

macOS keeps running the already-launched binary, so quit the app first, rebuild, re-sign, and
relaunch:

```bash
pkill -x StorageBar
swiftc -O main.swift -o StorageBar.app/Contents/MacOS/StorageBar
codesign --force --sign - StorageBar.app
open StorageBar.app
```

Skipping `codesign` after a rebuild leaves the bundle in a broken state, because replacing the
executable invalidates the existing signature.

## Uninstalling

```bash
pkill -x StorageBar
rm -rf /Applications/StorageBar.app
```

If you added it as a login item, remove the entry in
**System Settings > General > Login Items & Extensions** as well.

## Project layout

```
main.swift    Entire application: status item, menu, and the 60 second refresh timer
Info.plist    Bundle metadata (identifier, version, LSUIElement, minimum system version)
```

Build products (`StorageBar.app/` and the bare `StorageBar` executable) are not tracked.
