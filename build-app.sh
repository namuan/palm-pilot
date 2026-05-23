#!/bin/bash
set -euo pipefail

PROJECT="PalmPilot"
SCHEME="${PROJECT}"
CONFIGURATION="${1:-debug}"
BUILD_DIR=".build"
ICON_PNG="assets/icon.png"
ICONSET_DIR="${BUILD_DIR}/AppIcon.iconset"
ICON_ICNS="${BUILD_DIR}/AppIcon.icns"

if [ "$CONFIGURATION" = "release" ]; then
    SPM_FLAGS="-c release"
    BINARY_PATH="${BUILD_DIR}/release/${SCHEME}"
else
    SPM_FLAGS=""
    BINARY_PATH="${BUILD_DIR}/debug/${SCHEME}"
fi

echo "==> Building ${PROJECT} (${CONFIGURATION}) with SwiftPM..."

cd "$(dirname "$0")"

# Build with SPM
swift build $SPM_FLAGS

# Create .app bundle
APP_BUNDLE="${BUILD_DIR}/${CONFIGURATION}/${SCHEME}.app"
echo "==> Creating bundle at ${APP_BUNDLE}..."

rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BINARY_PATH}" "${APP_BUNDLE}/Contents/MacOS/${SCHEME}"

if [ -f "Resources/Info.plist" ]; then
    cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"
    echo "==> Copied Info.plist"
fi

if [ -f "${ICON_PNG}" ]; then
    echo "==> Converting app icon..."
    rm -rf "${ICONSET_DIR}"
    mkdir -p "${ICONSET_DIR}"

    sips -z 16 16   "${ICON_PNG}" --out "${ICONSET_DIR}/icon_16x16.png"       >/dev/null
    sips -z 32 32   "${ICON_PNG}" --out "${ICONSET_DIR}/icon_16x16@2x.png"    >/dev/null
    sips -z 32 32   "${ICON_PNG}" --out "${ICONSET_DIR}/icon_32x32.png"       >/dev/null
    sips -z 64 64   "${ICON_PNG}" --out "${ICONSET_DIR}/icon_32x32@2x.png"    >/dev/null
    sips -z 128 128 "${ICON_PNG}" --out "${ICONSET_DIR}/icon_128x128.png"     >/dev/null
    sips -z 256 256 "${ICON_PNG}" --out "${ICONSET_DIR}/icon_128x128@2x.png"  >/dev/null
    sips -z 256 256 "${ICON_PNG}" --out "${ICONSET_DIR}/icon_256x256.png"     >/dev/null
    sips -z 512 512 "${ICON_PNG}" --out "${ICONSET_DIR}/icon_256x256@2x.png"  >/dev/null
    sips -z 512 512 "${ICON_PNG}" --out "${ICONSET_DIR}/icon_512x512.png"     >/dev/null
    sips -z 1024 1024 "${ICON_PNG}" --out "${ICONSET_DIR}/icon_512x512@2x.png" >/dev/null

    iconutil -c icns "${ICONSET_DIR}" -o "${ICON_ICNS}"
    cp "${ICON_ICNS}" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
    echo "==> Copied AppIcon.icns"
fi

echo "==> Done: ${APP_BUNDLE}"
