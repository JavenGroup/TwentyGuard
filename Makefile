SWIFT_BUILD_FLAGS ?= --disable-sandbox --cache-path .build/cache --config-path .build/config --scratch-path .build

build:
	swift build $(SWIFT_BUILD_FLAGS) -c release

run:
	swift run $(SWIFT_BUILD_FLAGS)

clean:
	swift package clean

# Build standalone app bundle
build-app: clean
	@echo "🔨 Building standalone app..."
	@mkdir -p build
	@swift build $(SWIFT_BUILD_FLAGS) -c release
	@rm -rf "build/20-20-20.app"
	@mkdir -p "build/20-20-20.app/Contents/MacOS"
	@mkdir -p "build/20-20-20.app/Contents/Resources"
	@cp ./.build/release/TwentyTwentyTwenty "build/20-20-20.app/Contents/MacOS/"
	@cp Info.plist "build/20-20-20.app/Contents/"
	@cp -r Sources/TwentyTwentyTwenty.xcassets "build/20-20-20.app/Contents/Resources/"
	@cp -r Sources/TwentyTwentyTwenty/Resources "build/20-20-20.app/Contents/Resources/"
	@echo "🎨 Copying app icon..."
	@cp Sources/TwentyTwentyTwenty/Resources/AppIcon.icns "build/20-20-20.app/Contents/Resources/AppIcon.icns"
	@echo "🔏 Signing app bundle..."
	@codesign --force --deep --sign - "build/20-20-20.app"
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
