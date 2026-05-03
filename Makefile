SWIFT_BUILD_FLAGS ?= --disable-sandbox --cache-path .build/cache --config-path .build/config --scratch-path .build
APP_NAME := TwentyGuard
LEGACY_APP_NAME := 20-20-20
EXECUTABLE := TwentyTwentyTwenty
BUILD_APP := build/$(APP_NAME).app
LEGACY_BUILD_APP := build/$(LEGACY_APP_NAME).app
INSTALL_APP := /Applications/$(APP_NAME).app
LEGACY_INSTALL_APP := /Applications/$(LEGACY_APP_NAME).app

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
	@rm -rf "$(BUILD_APP)" "$(LEGACY_BUILD_APP)"
	@mkdir -p "$(BUILD_APP)/Contents/MacOS"
	@mkdir -p "$(BUILD_APP)/Contents/Resources"
	@cp ./.build/release/$(EXECUTABLE) "$(BUILD_APP)/Contents/MacOS/"
	@cp Info.plist "$(BUILD_APP)/Contents/"
	@cp -r Sources/TwentyTwentyTwenty.xcassets "$(BUILD_APP)/Contents/Resources/"
	@cp -r Sources/TwentyTwentyTwenty/Resources "$(BUILD_APP)/Contents/Resources/"
	@echo "🎨 Copying app icon..."
	@cp Sources/TwentyTwentyTwenty/Resources/AppIcon.icns "$(BUILD_APP)/Contents/Resources/AppIcon.icns"
	@echo "🔏 Signing app bundle..."
	@codesign --force --deep --sign - "$(BUILD_APP)"
	@echo "✅ App bundle created at $(BUILD_APP)"

# Create distribution DMG
dmg: build-app
	@./scripts/create-dmg.sh

# Install app to Applications folder (replaces existing version)
install: build-app
	@echo "🔄 Installing app to Applications folder..."
	@echo "⚠️  Stopping existing app process if needed..."
	@pkill -x "$(EXECUTABLE)" || true
	@pkill -f "$(INSTALL_APP)" || true
	@pkill -f "$(LEGACY_INSTALL_APP)" || true
	@sleep 1
	@if [ -d "$(INSTALL_APP)" ]; then \
		echo "🗑️  Removing old TwentyGuard version..."; \
		rm -rf "$(INSTALL_APP)"; \
	fi
	@if [ -d "$(LEGACY_INSTALL_APP)" ]; then \
		echo "🗑️  Removing legacy 20-20-20 version..."; \
		sleep 1; \
		rm -rf "$(LEGACY_INSTALL_APP)"; \
	fi
	@echo "📋 Copying new version to Applications..."
	@cp -R "$(BUILD_APP)" "/Applications/"
	@echo "✅ App installed successfully to $(INSTALL_APP)"
	@echo "💡 You can now launch it from Applications or use 'make launch'"

# Launch the installed app from Applications
launch:
	@echo "🚀 Launching app from Applications..."
	@open "$(INSTALL_APP)"

.PHONY: build run clean build-app dmg install launch
