build:
	swift build -c release

run:
	swift run

clean:
	swift package clean

# Build standalone app bundle
build-app: clean
	@echo "🔨 Building standalone app..."
	@mkdir -p build
	@swift build -c release
	@mkdir -p "build/20-20-20.app/Contents/MacOS"
	@mkdir -p "build/20-20-20.app/Contents/Resources"
	@cp ./.build/release/TwentyTwentyTwenty "build/20-20-20.app/Contents/MacOS/"
	@cp Info.plist "build/20-20-20.app/Contents/"
	@cp -r Sources/TwentyTwentyTwenty.xcassets "build/20-20-20.app/Contents/Resources/"
	@cp -r Sources/TwentyTwentyTwenty/Resources "build/20-20-20.app/Contents/Resources/"
	@echo "🎨 Processing app icons..."
	@mkdir -p "build/20-20-20.app/Contents/Resources/AppIcon.iconset"
	@cp Sources/TwentyTwentyTwenty.xcassets/AppIcon.appiconset/16-mac.png "build/20-20-20.app/Contents/Resources/AppIcon.iconset/icon_16x16.png"
	@cp Sources/TwentyTwentyTwenty.xcassets/AppIcon.appiconset/32-mac.png "build/20-20-20.app/Contents/Resources/AppIcon.iconset/icon_16x16@2x.png"
	@cp Sources/TwentyTwentyTwenty.xcassets/AppIcon.appiconset/32-mac.png "build/20-20-20.app/Contents/Resources/AppIcon.iconset/icon_32x32.png"
	@cp Sources/TwentyTwentyTwenty.xcassets/AppIcon.appiconset/64-mac.png "build/20-20-20.app/Contents/Resources/AppIcon.iconset/icon_32x32@2x.png"
	@cp Sources/TwentyTwentyTwenty.xcassets/AppIcon.appiconset/128-mac.png "build/20-20-20.app/Contents/Resources/AppIcon.iconset/icon_128x128.png"
	@cp Sources/TwentyTwentyTwenty.xcassets/AppIcon.appiconset/256-mac.png "build/20-20-20.app/Contents/Resources/AppIcon.iconset/icon_128x128@2x.png"
	@cp Sources/TwentyTwentyTwenty.xcassets/AppIcon.appiconset/256-mac.png "build/20-20-20.app/Contents/Resources/AppIcon.iconset/icon_256x256.png"
	@cp Sources/TwentyTwentyTwenty.xcassets/AppIcon.appiconset/512-mac.png "build/20-20-20.app/Contents/Resources/AppIcon.iconset/icon_256x256@2x.png"
	@cp Sources/TwentyTwentyTwenty.xcassets/AppIcon.appiconset/512-mac.png "build/20-20-20.app/Contents/Resources/AppIcon.iconset/icon_512x512.png"
	@cp Sources/TwentyTwentyTwenty.xcassets/AppIcon.appiconset/1024-mac.png "build/20-20-20.app/Contents/Resources/AppIcon.iconset/icon_512x512@2x.png"
	@iconutil -c icns "build/20-20-20.app/Contents/Resources/AppIcon.iconset" -o "build/20-20-20.app/Contents/Resources/AppIcon.icns"
	@rm -rf "build/20-20-20.app/Contents/Resources/AppIcon.iconset"
	@echo "✅ App bundle created at build/20-20-20.app"

# Create distribution DMG
dmg: build-app
	@./create-dmg.sh

# Install app to Applications folder (replaces existing version)
install: build-app
	@echo "🔄 Installing app to Applications folder..."
	@if [ -d "/Applications/20-20-20.app" ]; then \
		echo "⚠️  Killing existing app process..."; \
		pkill -f "/Applications/20-20-20.app" || true; \
		sleep 1; \
		echo "🗑️  Removing old version..."; \
		rm -rf "/Applications/20-20-20.app"; \
	fi
	@echo "📋 Copying new version to Applications..."
	@cp -R "build/20-20-20.app" "/Applications/"
	@echo "✅ App installed successfully to /Applications/20-20-20.app"
	@echo "💡 You can now launch it from Applications or use 'make launch'"

# Launch the installed app from Applications
launch:
	@echo "🚀 Launching app from Applications..."
	@open "/Applications/20-20-20.app"

.PHONY: build run clean build-app dmg install launch