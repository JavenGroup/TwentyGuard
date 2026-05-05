#!/bin/bash

# TwentyGuard DMG Creation Script
# Creates a DMG container. The Makefile release target handles Developer ID
# signing, notarization, and stapling for public distribution.

set -e

# Configuration
APP_NAME="TwentyGuard"
APP_PATH="./build/${APP_NAME}.app"
DMG_NAME="TwentyGuard"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist 2>/dev/null || echo "1.5.0")
DMG_BACKGROUND_IMG="dmg_background.png"
DMG_WINDOW_X=200
DMG_WINDOW_Y=120
DMG_WINDOW_WIDTH=600
DMG_WINDOW_HEIGHT=400
DMG_ICON_SIZE=128
DMG_TEXT_SIZE=16

# Create build directory if it doesn't exist
mkdir -p build
mkdir -p dist

echo "📦 Creating DMG for ${APP_NAME}..."

# Step 1: Build the app if it doesn't exist
if [ ! -d "$APP_PATH" ]; then
    echo "🔨 Building the app..."
    make build-app
fi

# Step 2: Create temporary DMG
echo "🗂️  Creating temporary DMG..."
TEMP_DMG="temp_${DMG_NAME}.dmg"
FINAL_DMG="dist/${DMG_NAME}-v${VERSION}.dmg"

# Remove existing files
rm -f "${TEMP_DMG}"
rm -f "${FINAL_DMG}"

# Create the DMG
hdiutil create -srcfolder "$APP_PATH" -volname "${APP_NAME}" -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" -format UDRW -size 100m "${TEMP_DMG}"

# Step 3: Mount the DMG
echo "💿 Mounting DMG..."
DEVICE=$(hdiutil attach -readwrite -noverify "${TEMP_DMG}" | \
         egrep '^/dev/' | sed 1q | awk '{print $1}')
VOLUME="/Volumes/${APP_NAME}"

# Step 4: Customize the DMG
echo "🎨 Customizing DMG appearance..."

# Copy the app to the mounted volume (if not already there)
if [ ! -d "${VOLUME}/${APP_NAME}.app" ]; then
    cp -r "$APP_PATH" "${VOLUME}/"
fi

# Create Applications symlink if not exists
if [ ! -e "${VOLUME}/Applications" ]; then
    ln -s /Applications "${VOLUME}/Applications"
fi

# Set up the appearance with AppleScript
osascript <<EOF
tell application "Finder"
    tell disk "${APP_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {${DMG_WINDOW_X}, ${DMG_WINDOW_Y}, $((${DMG_WINDOW_X} + ${DMG_WINDOW_WIDTH})), $((${DMG_WINDOW_Y} + ${DMG_WINDOW_HEIGHT}))}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to ${DMG_ICON_SIZE}
        set text size of viewOptions to ${DMG_TEXT_SIZE}
        
        -- Position the app icon
        set position of item "${APP_NAME}.app" of container window to {150, 200}
        -- Position the Applications link  
        set position of item "Applications" of container window to {450, 200}
        
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Step 5: Make the DMG read-only and compress
echo "🗜️  Finalizing DMG..."

# Sync and unmount
sync
hdiutil detach "${DEVICE}"

# Convert to final compressed DMG
hdiutil convert "${TEMP_DMG}" -format UDZO -imagekey zlib-level=9 -o "${FINAL_DMG}"

# Clean up
rm -f "${TEMP_DMG}"

# Step 6: Show results
echo "✅ DMG created successfully!"
echo "📍 Location: ${FINAL_DMG}"
echo "📦 Size: $(du -h "${FINAL_DMG}" | cut -f1)"
echo ""
echo "ℹ️  Local DMG packaging complete."
echo "   For public releases, use the Makefile release target to sign and notarize."
