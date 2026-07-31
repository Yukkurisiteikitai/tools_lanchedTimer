#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="LaunchdMonitor"
DIST_DIR="dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"

echo "==> swift build -c release"
swift build -c release

echo "==> Assembling $APP_BUNDLE"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp ".build/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "Info.plist" "$APP_BUNDLE/Contents/Info.plist"

echo "==> Done: $APP_BUNDLE"
echo "起動するには: open \"$APP_BUNDLE\""
