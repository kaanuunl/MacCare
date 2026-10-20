#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="MacCare"
APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"

cd "$PROJECT_DIR"
swift build --configuration release

mkdir -p "$CONTENTS_DIR/MacOS"
mkdir -p "$CONTENTS_DIR/Resources"

cp ".build/release/$APP_NAME" "$CONTENTS_DIR/MacOS/$APP_NAME"
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$CONTENTS_DIR/Resources/AppIcon.icns"
fi

# Touch bundle to force Finder icon refresh
touch "$APP_BUNDLE"

printf 'Application built: %s\n' "$APP_BUNDLE"
