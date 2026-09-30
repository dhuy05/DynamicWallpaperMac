#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "========================================================="
echo "   Xuất Bản Ứng Dụng Dynamic Wallpaper cho macOS"
echo "========================================================="

# 1. Rebuild latest Release version
echo "1. Đang biên dịch bản Release mới nhất..."
./build_app.sh

APP_BUNDLE="./build/DynamicWallpaper.app"
EXPORT_DIR="./Export"
rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

# 2. Copy .app to Export folder
echo "2. Chuẩn bị file ứng dụng..."
cp -R "$APP_BUNDLE" "$EXPORT_DIR/DynamicWallpaper.app"

# 3. Create DMG Installer
echo "3. Đang tạo tệp cài đặt đĩa ảnh (.dmg)..."
DMG_TEMP="./build/dmg_temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

cp -R "$APP_BUNDLE" "$DMG_TEMP/DynamicWallpaper.app"
ln -s /Applications "$DMG_TEMP/Applications"

DMG_OUTPUT="$EXPORT_DIR/DynamicWallpaper_v1.0.dmg"
rm -f "$DMG_OUTPUT"

hdiutil create -volname "Dynamic Wallpaper" \
               -srcfolder "$DMG_TEMP" \
               -ov -format UDZO \
               "$DMG_OUTPUT"

rm -rf "$DMG_TEMP"

# 4. Create ZIP archive
echo "4. Đang tạo file nén .zip để tiện chia sẻ..."
(cd "$EXPORT_DIR" && zip -r -y "DynamicWallpaper_v1.0.zip" "DynamicWallpaper.app")

# 5. Optionally copy to /Applications for instant use
echo "5. Cài đặt bản mới nhất vào thư mục /Applications..."
rm -rf "/Applications/DynamicWallpaper.app"
cp -R "$APP_BUNDLE" "/Applications/DynamicWallpaper.app"

echo ""
echo "========================================================="
echo "🎉 XUẤT BẢN THÀNH CÔNG!"
echo "Các file đã được tạo tại thư mục: $EXPORT_DIR"
echo "  1. Ứng dụng độc lập:     $EXPORT_DIR/DynamicWallpaper.app"
echo "  2. Bộ cài đặt macOS:     $EXPORT_DIR/DynamicWallpaper_v1.0.dmg"
echo "  3. Tệp nén chia sẻ:      $EXPORT_DIR/DynamicWallpaper_v1.0.zip"
echo "  4. Đã tự động cài vào:   /Applications/DynamicWallpaper.app"
echo "========================================================="
