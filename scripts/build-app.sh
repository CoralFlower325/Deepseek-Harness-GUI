#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
APP_NAME="DeepSeek Harness"
EXECUTABLE_NAME="DeepSeekHarnessMac"
APP_DIR="$PROJECT_DIR/dist/$APP_NAME.app"

cd "$PROJECT_DIR"
swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp ".build/release/$EXECUTABLE_NAME" "$APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

if [[ -d "$PROJECT_DIR/Resources/engine" ]]; then
  COPYFILE_DISABLE=1 cp -R "$PROJECT_DIR/Resources/engine" "$APP_DIR/Contents/Resources/engine"
fi

if [[ -d "$PROJECT_DIR/Resources/seed-runtime" ]]; then
  COPYFILE_DISABLE=1 cp -R "$PROJECT_DIR/Resources/seed-runtime" "$APP_DIR/Contents/Resources/seed-runtime"
fi

chmod +x "$APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"
find "$APP_DIR" -name '.DS_Store' -delete
xattr -cr "$APP_DIR"
echo "Built unsigned app bundle. Developer ID signing and notarization are not performed."

echo "$APP_DIR"
