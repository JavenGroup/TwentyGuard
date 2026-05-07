#!/usr/bin/env bash

# TwentyGuard DMG Creation Script
# Creates a DMG container. The Makefile release target handles Developer ID
# signing, notarization, and stapling for public distribution.

set -euo pipefail

APP_NAME="TwentyGuard"
APP_PATH="./build/${APP_NAME}.app"
DMG_NAME="TwentyGuard"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist 2>/dev/null || echo "1.5.0")
DMG_WINDOW_X=200
DMG_WINDOW_Y=120
DMG_WINDOW_WIDTH=600
DMG_WINDOW_HEIGHT=400
DMG_ICON_SIZE=128
DMG_TEXT_SIZE=16

TEMP_DMG="temp_${DMG_NAME}.dmg"
FINAL_DMG="dist/${DMG_NAME}-v${VERSION}.dmg"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/twentyguard-dmg-staging.XXXXXX")"
DEVICE=""
VOLUME=""

cleanup() {
    if [ -n "$VOLUME" ] && [ -d "$VOLUME" ]; then
        hdiutil detach "$VOLUME" >/dev/null 2>&1 || true
    elif [ -n "$DEVICE" ]; then
        hdiutil detach "$DEVICE" >/dev/null 2>&1 || true
    fi

    rm -rf "$STAGING_DIR"
    rm -f "$TEMP_DMG"
}
trap cleanup EXIT

echo "📦 Creating DMG for ${APP_NAME}..."

mkdir -p build
mkdir -p dist

if [ ! -d "$APP_PATH" ]; then
    echo "🔨 Building the app..."
    make build-app
fi

echo "🧱 Preparing DMG staging directory..."
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

echo "🗂️  Creating temporary DMG..."
rm -f "$TEMP_DMG" "$FINAL_DMG"
hdiutil create -srcfolder "$STAGING_DIR" -volname "$APP_NAME" -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" -format UDRW -size 100m "$TEMP_DMG"

echo "💿 Mounting DMG..."
ATTACH_OUTPUT="$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG")"
DEVICE="$(printf '%s\n' "$ATTACH_OUTPUT" | awk '/^\/dev\// {print $1; exit}')"
VOLUME="$(printf '%s\n' "$ATTACH_OUTPUT" | awk -F '\t' '/\/Volumes\// {print $NF; exit}')"

if [ -z "$DEVICE" ] || [ -z "$VOLUME" ] || [ ! -d "$VOLUME" ]; then
    echo "$ATTACH_OUTPUT"
    echo "❌ Failed to locate mounted DMG volume" >&2
    exit 1
fi

echo "🎨 Customizing DMG appearance..."
if ! osascript <<EOF
tell application "Finder"
    set volumeFolder to POSIX file "${VOLUME}" as alias
    open volumeFolder
    set current view of container window of volumeFolder to icon view
    set toolbar visible of container window of volumeFolder to false
    set statusbar visible of container window of volumeFolder to false
    set the bounds of container window of volumeFolder to {${DMG_WINDOW_X}, ${DMG_WINDOW_Y}, $((${DMG_WINDOW_X} + ${DMG_WINDOW_WIDTH})), $((${DMG_WINDOW_Y} + ${DMG_WINDOW_HEIGHT}))}
    set viewOptions to the icon view options of container window of volumeFolder
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to ${DMG_ICON_SIZE}
    set text size of viewOptions to ${DMG_TEXT_SIZE}
    set position of item "${APP_NAME}.app" of volumeFolder to {150, 200}
    set position of item "Applications" of volumeFolder to {450, 200}
    close container window of volumeFolder
    open volumeFolder
    update volumeFolder without registering applications
    delay 2
end tell
EOF
then
    echo "⚠️  Finder appearance customization failed; continuing with verified DMG layout."
fi

echo "🗜️  Finalizing DMG..."
sync
hdiutil detach "$DEVICE"
DEVICE=""
VOLUME=""

hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG"

echo "✅ DMG created successfully!"
echo "📍 Location: ${FINAL_DMG}"
echo "📦 Size: $(du -h "$FINAL_DMG" | cut -f1)"
echo ""
echo "ℹ️  Local DMG packaging complete."
echo "   For public releases, use the Makefile release target to sign and notarize."
