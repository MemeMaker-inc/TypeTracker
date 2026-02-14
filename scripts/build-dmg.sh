#!/bin/bash
set -e

VERSION="${1:-1.0.0}"
APP_NAME="TypeTracker"
BUNDLE_ID="mememaker.jp.typescrollcounter"

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
RELEASE_DIR="$BUILD_DIR/release"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
APP_PATH="$RELEASE_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME-$VERSION.dmg"

# Developer ID (公開配布時に設定)
# DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"
DEVELOPER_ID=""

# Apple ID for notarization
# APPLE_ID="your@email.com"
# APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"  # App-specific password
# TEAM_ID="XXXXXXXXXX"
APPLE_ID=""
APP_PASSWORD=""
TEAM_ID=""

echo "=== Building $APP_NAME v$VERSION ==="

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$RELEASE_DIR"

# Archive
echo "Archiving..."
xcodebuild -project "$PROJECT_DIR/typescrollcounter.xcodeproj" \
    -scheme typescrollcounter \
    -configuration Release \
    archive \
    -archivePath "$ARCHIVE_PATH" \
    -quiet

# Copy app
cp -R "$ARCHIVE_PATH/Products/Applications/typescrollcounter.app" "$APP_PATH"

# Rename to proper name
# (already named TypeTracker.app after copy)

# Sign with Developer ID (if available)
if [ -n "$DEVELOPER_ID" ]; then
    echo "Signing with Developer ID..."
    codesign --force --deep --options runtime \
        --sign "$DEVELOPER_ID" \
        "$APP_PATH"

    # Verify
    codesign --verify --verbose "$APP_PATH"
fi

# Create DMG
echo "Creating DMG..."
ln -sf /Applications "$RELEASE_DIR/Applications"
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$RELEASE_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

# Sign DMG (if Developer ID available)
if [ -n "$DEVELOPER_ID" ]; then
    echo "Signing DMG..."
    codesign --force --sign "$DEVELOPER_ID" "$DMG_PATH"
fi

# Notarize (if credentials available)
if [ -n "$APPLE_ID" ] && [ -n "$APP_PASSWORD" ] && [ -n "$TEAM_ID" ]; then
    echo "Notarizing..."
    xcrun notarytool submit "$DMG_PATH" \
        --apple-id "$APPLE_ID" \
        --password "$APP_PASSWORD" \
        --team-id "$TEAM_ID" \
        --wait

    echo "Stapling..."
    xcrun stapler staple "$DMG_PATH"
fi

echo ""
echo "=== Done ==="
echo "DMG: $DMG_PATH"
ls -lh "$DMG_PATH"
