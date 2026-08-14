#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
APP_DIR="$PROJECT_DIR/dist/DeepSeek Harness.app"
DMG_PATH="$PROJECT_DIR/dist/DeepSeek-Harness-Mac.dmg"
STAGING_DIR="$PROJECT_DIR/dist/dmg-root"

if [[ ! -d "$APP_DIR" ]]; then
  "$PROJECT_DIR/scripts/build-app.sh"
fi

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
