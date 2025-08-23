#!/bin/bash

# 20-20-20 App DMG Creation Script
# Creates a professional DMG file for distribution

set -e

# Configuration
APP_NAME="20-20-20"
APP_PATH="./build/20-20-20.app"
DMG_NAME="20-20-20-Eye-Protection-App"
VERSION="1.0.0"
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

# Create Applications symlink (remove if exists)
rm -f "${VOLUME}/Applications"
ln -s /Applications "${VOLUME}/Applications"

# Create a simple README for installation instructions
cat > "${VOLUME}/Install Instructions.txt" << EOF
📦 20-20-20 Eye Protection App Installation

1. Drag "20-20-20.app" to the "Applications" folder
2. Launch the app from Applications folder
3. On first run, you may need to:
   - Right-click the app and select "Open"
   - Or go to System Preferences > Security & Privacy > "Open Anyway"

Thanks for using 20-20-20! 👀
EOF

# Create background images directory (hidden)
mkdir -p "${VOLUME}/.background"

# Create a simple background (if you have one)
if [ -f "$DMG_BACKGROUND_IMG" ]; then
    cp "$DMG_BACKGROUND_IMG" "${VOLUME}/.background/"
else
    echo "ℹ️  No background image found, using default"
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
        set position of item "${APP_NAME}.app" of container window to {120, 180}
        -- Position the Applications link  
        set position of item "Applications" of container window to {420, 180}
        -- Position the install instructions
        set position of item "Install Instructions.txt" of container window to {270, 300}
        
        -- Set background if available
        try
            set background picture of viewOptions to file ".background:${DMG_BACKGROUND_IMG}"
        end try
        
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
echo "🚀 Ready for distribution!"
echo "   You can now upload this DMG to GitHub Releases"