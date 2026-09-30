#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "  Building Dynamic Wallpaper for macOS"
echo "=========================================="

# Build using xcodebuild
xcodebuild -project DynamicWallpaper.xcodeproj \
           -scheme DynamicWallpaper \
           -configuration Release \
           -derivedDataPath ./build/DerivedData \
           build

APP_SRC="./build/DerivedData/Build/Products/Release/DynamicWallpaper.app"
APP_DEST="./build/DynamicWallpaper.app"

rm -rf "$APP_DEST"
cp -R "$APP_SRC" "$APP_DEST"

echo ""
echo "✅ Build Thành công!"
echo "Ứng dụng đã sẵn sàng tại: $APP_DEST"
echo "Bạn có thể mở ứng dụng bằng lệnh: open $APP_DEST"
