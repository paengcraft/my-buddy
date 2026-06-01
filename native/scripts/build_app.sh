#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="${APP_NAME:-My Buddy}"
BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER:-com.mybuddy.desktop}"
EXECUTABLE_NAME="MyBuddy"
APP_DIR="$ROOT_DIR/build/$APP_NAME.app"
DMG_PATH="${DMG_PATH:-$ROOT_DIR/build/${APP_NAME}_0.1.0_aarch64.dmg}"

cd "$ROOT_DIR"
swift build -c release

rm -rf "$APP_DIR" "$DMG_PATH"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$ROOT_DIR/.build/release/$EXECUTABLE_NAME" "$APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"
cp "$ROOT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $APP_NAME" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName $APP_NAME" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_IDENTIFIER" "$APP_DIR/Contents/Info.plist"
cp -R "$ROOT_DIR/.build/release/MyBuddyNative_MyBuddyApp.bundle" "$APP_DIR/Contents/Resources/"

if [[ -f "$ROOT_DIR/Resources/icon.icns" ]]; then
  cp "$ROOT_DIR/Resources/icon.icns" "$APP_DIR/Contents/Resources/icon.icns"
fi

codesign --force --deep --sign "${CODESIGN_IDENTITY:--}" "$APP_DIR"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$APP_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "$APP_DIR"
echo "$DMG_PATH"
