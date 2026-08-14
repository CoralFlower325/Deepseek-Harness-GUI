#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
APP_DIR="$PROJECT_DIR/dist/DeepSeek Harness.app"
APP_VERSION="$(plutil -extract CFBundleShortVersionString raw "$PROJECT_DIR/Resources/Info.plist")"
BUILD_ARCH="$(uname -m)"
DMG_PATH="$PROJECT_DIR/dist/Deepseek-Harness-GUI-v$APP_VERSION-$BUILD_ARCH.dmg"
STAGING_DIR="$PROJECT_DIR/dist/dmg-root"

"$PROJECT_DIR/scripts/build-app.sh"

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_DIR" "$STAGING_DIR/DeepSeek Harness.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "DeepSeek Harness" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGING_DIR"
echo "$DMG_PATH"
