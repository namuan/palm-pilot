#!/bin/bash
set -euo pipefail

PROJECT="PalmPilot"
SCHEME="${PROJECT}"
CONFIGURATION="${1:-debug}"
BUILD_DIR=".build"

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

echo "==> Done: ${APP_BUNDLE}"
