#!/bin/zsh
# Builds StorageBar.app — this section on its own, as its own menu bar app.
#
#   ./build.sh          build and re-sign the bundle
#   ./build.sh --run    build, re-sign, and relaunch the app
#
# The section is written against the MacBar host, which defines BarSection and
# the drawing it uses. That host is a checkout of
#
#   https://github.com/ainahtokyandry/mac-setup
#
# found in MACBAR_HOST, or beside this repository, or under $HOME/Projects. There
# is no copy of it here on purpose: one definition of the contract, so a section
# cannot drift away from the app that hosts it.
#
# Building StorageBar is optional. Normally this section is one of several behind
# a single menu bar item, and mac-setup/menubar/build.sh is what assembles that.
#
# macOS keeps running the already-launched binary, so the app is stopped first.
# The ad hoc codesign step is required: replacing the executable invalidates the
# existing signature, and an unsigned bundle will not launch on recent macOS.

set -euo pipefail

HERE="${0:A:h}"
APP="$HERE/StorageBar.app"
RUN=0

for arg in "$@"; do
  case "$arg" in
    --run) RUN=1 ;;
    *)     APP="${arg:A}" ;;
  esac
done

die() { print -u2 -- "\033[31merror:\033[0m $*"; exit 1 }

command -v swiftc >/dev/null || die "swiftc not found — install the Xcode Command Line Tools: xcode-select --install"

# ------------------------------------------------------------------- the host

find_host() {
  local candidate
  for candidate in \
    "${MACBAR_HOST:-}" \
    "$HERE/../mac-setup/menubar" \
    "$HOME/Projects/mac-setup/menubar"
  do
    [ -n "$candidate" ] || continue
    [ -f "$candidate/Support.swift" ] || continue
    print -- "${candidate:A}"
    return 0
  done
  return 1
}

HOST="$(find_host)" || die "could not find the MacBar host.
  Clone it next to this repository:
      git clone https://github.com/ainahtokyandry/mac-setup.git ${HERE:h}/mac-setup
  or point at an existing checkout:
      MACBAR_HOST=/path/to/mac-setup/menubar ./build.sh"

print -- "Host: $HOST"

# ---------------------------------------------------------------------- build

pkill -x StorageBar 2>/dev/null || true

mkdir -p "$APP/Contents/MacOS"
cp "$HERE/Info.plist" "$APP/Contents/Info.plist"

swiftc -O \
  "$HOST/Support.swift" \
  "$HOST/Controller.swift" \
  "$HOST/Host.swift" \
  "$HERE/StorageSection.swift" \
  "$HERE/main.swift" \
  -o "$APP/Contents/MacOS/StorageBar"

codesign --force --sign - "$APP"

print -- "Built $APP"

if [ "$RUN" = 1 ]; then
  open "$APP"
  print -- "Launched — look for it in the menu bar"
fi
