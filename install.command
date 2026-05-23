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
ICONSET_DIR="$ROOT/.build/AppIcon.iconset"
ICON_ICNS="$ROOT/.build/AppIcon.icns"
DEST_DIR="$HOME/Applications"
DEST_APP="$DEST_DIR/$APP_NAME.app"

create_icns_from_png() {
  if [ ! -f "$ICON_PNG" ]; then
    echo "No icon source at $ICON_PNG. Skipping icon."
    return 0
  fi

  if ! command -v sips >/dev/null 2>&1 || ! command -v iconutil >/dev/null 2>&1; then
    echo "Warning: sips/iconutil not available. Skipping icon."
    return 0
  fi

  rm -rf "$ICONSET_DIR"
  mkdir -p "$ICONSET_DIR"

  echo "Generating AppIcon.icns from icon.png..."
  sips -z 16 16   "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16.png"       >/dev/null
  sips -z 32 32   "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png"    >/dev/null
  sips -z 32 32   "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32.png"       >/dev/null
  sips -z 64 64   "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png"    >/dev/null
  sips -z 128 128 "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128.png"     >/dev/null
  sips -z 256 256 "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png"  >/dev/null
  sips -z 256 256 "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256.png"     >/dev/null
  sips -z 512 512 "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png"  >/dev/null
  sips -z 512 512 "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512.png"     >/dev/null
  sips -z 1024 1024 "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null

  iconutil -c icns "$ICONSET_DIR" -o "$ICON_ICNS"
}

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

echo "Quitting any running $APP_NAME instances..."
pkill -x "$APP_NAME" 2>/dev/null || true

echo "Clearing TCC permissions for $BUNDLE_ID..."
tccutil reset Camera        "$BUNDLE_ID" 2>/dev/null || true
tccutil reset Microphone    "$BUNDLE_ID" 2>/dev/null || true
tccutil reset Accessibility "$BUNDLE_ID" 2>/dev/null || true

create_icns_from_png

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
