#!/bin/bash
# Usage: ./build.sh [install]
# Set SDKROOT to force a specific macOS SDK.
set -euo pipefail
cd "$(dirname "$0")"

APP="build/EtherSwitch.app"
DEST="$HOME/Applications/EtherSwitch.app"
MIN_MACOS="13.0"
SOURCES=(Sources/*.swift)

compile() {
  local arch=$1 sdk=$2
  swiftc -swift-version 5 -O -sdk "$sdk" -target "$arch-apple-macos$MIN_MACOS" \
    -o "build/EtherSwitch-$arch" "${SOURCES[@]}"
}

# Command Line Tools can ship SDKs newer than their compiler; fall back to the newest one that works.
pick_sdk() {
  local candidates=()
  if [[ -n "${SDKROOT:-}" ]]; then
    candidates=("$SDKROOT")
  else
    candidates+=("$(xcrun --sdk macosx --show-sdk-path)")
    while IFS= read -r sdk; do candidates+=("$sdk"); done < <(
      ls -d "$(xcode-select -p)"/SDKs/MacOSX[0-9]*.sdk 2>/dev/null | sort -rV)
  fi
  for sdk in "${candidates[@]}"; do
    if compile arm64 "$sdk" 2>build/compile.log; then
      echo "$sdk"
      return
    fi
  done
  cat build/compile.log >&2
  exit 1
}

rm -rf build
mkdir -p "$APP/Contents/MacOS"

SDK=$(pick_sdk)
echo "Using SDK: $SDK"
compile x86_64 "$SDK"
lipo -create -output "$APP/Contents/MacOS/EtherSwitch" build/EtherSwitch-arm64 build/EtherSwitch-x86_64
rm build/EtherSwitch-* build/compile.log

cp Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
echo "Built $APP"

if [[ "${1:-}" == "install" ]]; then
  pkill -x EtherSwitch || true
  mkdir -p "$HOME/Applications"
  rm -rf "$DEST"
  cp -R "$APP" "$DEST"
  open "$DEST"
  echo "Installed to $DEST"
fi
