#!/bin/bash
set -euo pipefail

convert_icon() {
    local icon_png="${1:?Usage: convert-icon.sh <icon.png> <output.icns>}"
    local output_icns="${2:?Usage: convert-icon.sh <icon.png> <output.icns>}"
    local iconset_dir="$(dirname "$output_icns")/AppIcon.iconset"

    if [ ! -f "$icon_png" ]; then
        echo "No icon source at $icon_png. Skipping icon."
        return 0
    fi

    if ! command -v sips >/dev/null 2>&1 || ! command -v iconutil >/dev/null 2>&1; then
        echo "Warning: sips/iconutil not available. Skipping icon."
        return 0
    fi

    rm -rf "$iconset_dir"
    mkdir -p "$iconset_dir"

    echo "Generating AppIcon.icns from $(basename "$icon_png")..."
    sips -z 16 16      "$icon_png" --out "$iconset_dir/icon_16x16.png"       >/dev/null
    sips -z 32 32      "$icon_png" --out "$iconset_dir/icon_16x16@2x.png"    >/dev/null
    sips -z 32 32      "$icon_png" --out "$iconset_dir/icon_32x32.png"       >/dev/null
    sips -z 64 64      "$icon_png" --out "$iconset_dir/icon_32x32@2x.png"    >/dev/null
    sips -z 128 128    "$icon_png" --out "$iconset_dir/icon_128x128.png"     >/dev/null
    sips -z 256 256    "$icon_png" --out "$iconset_dir/icon_128x128@2x.png"  >/dev/null
    sips -z 256 256    "$icon_png" --out "$iconset_dir/icon_256x256.png"     >/dev/null
    sips -z 512 512    "$icon_png" --out "$iconset_dir/icon_256x256@2x.png"  >/dev/null
    sips -z 512 512    "$icon_png" --out "$iconset_dir/icon_512x512.png"     >/dev/null
    sips -z 1024 1024  "$icon_png" --out "$iconset_dir/icon_512x512@2x.png"  >/dev/null

    iconutil -c icns "$iconset_dir" -o "$output_icns"
}
