#!/bin/bash
set -euo pipefail

if ! command -v swift >/dev/null 2>&1; then
  echo "Error: 'swift' not found."
  echo "Install Xcode Command Line Tools (no full Xcode needed):"
  echo "  xcode-select --install"
  exit 1
fi

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Error: No active developer directory found."
  echo "Run: xcode-select --install"
  exit 1
fi

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="PalmPilot"
BINARY="$ROOT/.build/release/$APP_NAME"
PLIST="$ROOT/Resources/Info.plist"
ICON_PNG="$ROOT/assets/icon.png"
ICON_ICNS="$ROOT/.build/AppIcon.icns"
DEST_DIR="$HOME/Applications"
DEST_APP="$DEST_DIR/$APP_NAME.app"

build_app_bundle() {
  local bundle="$1"
  local binary="$2"
  local macos_dir="$bundle/Contents/MacOS"
  local resources_dir="$bundle/Contents/Resources"

  rm -rf "$bundle"
  mkdir -p "$macos_dir" "$resources_dir"

  cp "$binary" "$macos_dir/$APP_NAME"
  chmod +x "$macos_dir/$APP_NAME"

  if [ -f "$PLIST" ]; then
    cp "$PLIST" "$bundle/Contents/Info.plist"
  else
    echo "Warning: No Info.plist at $PLIST. Generating minimal plist."
    cat > "$bundle/Contents/Info.plist" <<'EOPLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>PalmPilot</string>
  <key>CFBundleIdentifier</key>
  <string>com.palmpilot.app</string>
  <key>CFBundleName</key>
  <string>Palm Pilot</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSCameraUsageDescription</key>
  <string>Palm Pilot uses your camera to detect hand gestures. All processing is done entirely on-device.</string>
</dict>
</plist>
EOPLIST
  fi

  if [ -f "$ICON_ICNS" ]; then
    cp "$ICON_ICNS" "$resources_dir/AppIcon.icns"
  fi
}

BUNDLE_ID="com.palmpilot.app"

cd "$ROOT"

source ./convert-icon.sh

echo "Quitting any running $APP_NAME instances..."
pkill -x "$APP_NAME" 2>/dev/null || true

echo "Clearing TCC permissions for $BUNDLE_ID..."
tccutil reset Camera        "$BUNDLE_ID" 2>/dev/null || true
tccutil reset Microphone    "$BUNDLE_ID" 2>/dev/null || true
tccutil reset Accessibility "$BUNDLE_ID" 2>/dev/null || true

convert_icon "$ICON_PNG" "$ICON_ICNS"

echo "Building $APP_NAME (release)..."
swift build -c release

if [ ! -f "$BINARY" ]; then
  echo "Error: Build succeeded but binary not found at: $BINARY"
  exit 1
fi

echo "Creating app bundle..."
mkdir -p "$DEST_DIR"
rm -rf "$DEST_APP"
build_app_bundle "$DEST_APP" "$BINARY"

echo "Installed to $DEST_APP"
echo "Done."
open "$DEST_APP"
