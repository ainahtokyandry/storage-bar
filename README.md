# storage-bar

The **storage section** of [MacBar](https://github.com/ainahtokyandry/mac-setup): free space on
the startup disk, in the menu bar, as `free / total`.

```
118 GB / 494 GB
```

It used to be a menu bar app of its own. It still builds as one, but its normal home is
alongside the other sections behind a single menu bar item, so that a handful of small tools
cost one slot in the menu bar instead of one each:

```
⌾ 118 GB · 42·61·18% · ◷ Mon 08:00
```

In the dropdown the section contributes its own block:

- **Available** — free space, coloured once it drops below 10% and again below 5%
- **Used** — used space, with the percentage of the disk consumed
- **Total** — capacity of the volume mounted at `/`
- **Open Storage Settings…** — jump straight to the Storage pane in System Settings

### Details

- Free space is read via `volumeAvailableCapacityForImportantUsage`, the same measure Finder
  uses, so the number accounts for purgeable space and matches what macOS reports elsewhere.
- The reading refreshes every 60 seconds, and whenever the menu is opened.
- Sizes are formatted with `ByteCountFormatter` in file style (base 1000, matching Finder).
- Swift against AppKit. No third-party dependencies.

## How it fits together

`StorageSection.swift` is the whole of it: one class conforming to `BarSection`, the protocol
the MacBar host defines. The host owns the status item, the dropdown, the colours and the date
formatting; this repository owns nothing but the reading.

```
StorageSection.swift   the section: one BarSection, polling, its block of the menu
main.swift             a standalone entry point — Host.run(sections: [StorageSection()])
build.sh               builds StorageBar.app against a MacBar host checkout
Info.plist             bundle metadata for the standalone app
```

There is deliberately **no copy of the host here**. `build.sh` compiles against a checkout of
[mac-setup](https://github.com/ainahtokyandry/mac-setup), found in `MACBAR_HOST`, or beside
this repository, or under `$HOME/Projects`. One definition of the contract means this section
cannot drift away from the app that hosts it.

## Requirements

- macOS 13 or later
- Xcode Command Line Tools (provides `swiftc` and `codesign`):
  ```sh
  xcode-select --install
  ```
- A checkout of [mac-setup](https://github.com/ainahtokyandry/mac-setup), which holds the host

## Usual install

You do not normally build this repository directly. MacBar's installer clones it, together with
the other sections, and builds the one app:

```sh
zsh -c "$(curl -fsSL https://raw.githubusercontent.com/ainahtokyandry/mac-setup/main/install.sh)"
```

## Building it on its own

Useful when working on the section itself:

```sh
git clone https://github.com/ainahtokyandry/mac-setup.git ../mac-setup   # the host
./build.sh --run
```

That yields `StorageBar.app` — one section, one menu bar item, no Dock icon. The readings are
also available without the menu bar:

```sh
./StorageBar.app/Contents/MacOS/StorageBar --print
```

```
Storage
  Available:  118 GB
  Used:       376 GB (76%)
  Total:      494 GB
```

Rebuilding is the same command; `build.sh` stops the running copy, rebuilds, and re-signs. The
ad hoc `codesign` step is not optional — replacing the executable invalidates the existing
signature, and an unsigned bundle will not launch on recent versions of macOS.

## Uninstalling

The standalone bundle is self-contained:

```sh
pkill -x StorageBar
rm -rf /Applications/StorageBar.app
```

If you added it as a login item, remove that entry in **System Settings > General > Login Items
& Extensions** as well. To remove MacBar instead, see
[mac-setup](https://github.com/ainahtokyandry/mac-setup).
