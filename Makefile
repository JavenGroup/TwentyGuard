SWIFT_BUILD_FLAGS ?= --disable-sandbox --cache-path .build/cache --config-path .build/config --scratch-path .build
APP_NAME := TwentyGuard
EXECUTABLE := TwentyGuard
BUILD_APP := build/$(APP_NAME).app
INSTALL_APP := /Applications/$(APP_NAME).app
VERSION := $(shell /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist 2>/dev/null || echo 0.0.0)
DMG := dist/$(APP_NAME)-v$(VERSION).dmg
APPLE_ID ?=
TEAM_ID ?=
DEVELOPER_ID_APPLICATION ?=
NOTARY_PROFILE ?= TwentyGuardNotary

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
	@rm -rf "$(BUILD_APP)"
	@mkdir -p "$(BUILD_APP)/Contents/MacOS"
	@mkdir -p "$(BUILD_APP)/Contents/Resources"
	@cp ./.build/release/$(EXECUTABLE) "$(BUILD_APP)/Contents/MacOS/"
	@cp Info.plist "$(BUILD_APP)/Contents/"
	@printf 'APPL????' > "$(BUILD_APP)/Contents/PkgInfo"
	@cp Sources/TwentyGuard/Resources/version-history.json "$(BUILD_APP)/Contents/Resources/"
	@cp Sources/TwentyGuard/Resources/statusbar_icon.png "$(BUILD_APP)/Contents/Resources/"
	@cp Sources/TwentyGuard/Resources/statusbar_icon@2x.png "$(BUILD_APP)/Contents/Resources/"
	@if ls ./.build/release/*.bundle >/dev/null 2>&1; then \
		cp -R ./.build/release/*.bundle "$(BUILD_APP)/Contents/Resources/"; \
	fi
	@echo "🎨 Copying app icon..."
	@cp Sources/TwentyGuard/Resources/AppIcon.icns "$(BUILD_APP)/Contents/Resources/AppIcon.icns"
	@echo "🔏 Signing app bundle..."
	@codesign --force --deep --sign - "$(BUILD_APP)"
	@./scripts/verify-app-bundle.sh "$(BUILD_APP)"
	@echo "✅ App bundle created at $(BUILD_APP)"

verify-app-bundle:
	@./scripts/verify-app-bundle.sh "$(BUILD_APP)"

verify-dmg:
	@./scripts/verify-dmg.sh "$(DMG)"

check-release-prereqs:
	@echo "🔎 Checking release signing prerequisites..."
	@if [ -z "$(TEAM_ID)" ]; then \
		echo "❌ TEAM_ID is required, for example: make check-release-prereqs TEAM_ID=VJ345Z9T8T"; \
		exit 1; \
	fi
	@if [ -z "$(DEVELOPER_ID_APPLICATION)" ]; then \
		echo "❌ DEVELOPER_ID_APPLICATION is required."; \
		echo "   Install a Developer ID Application certificate, then pass its full identity name."; \
		exit 1; \
	fi
	@security find-identity -v -p codesigning | grep -F "$(DEVELOPER_ID_APPLICATION)" >/dev/null || \
		(echo "❌ Developer ID identity not found in keychain: $(DEVELOPER_ID_APPLICATION)"; exit 1)
	@xcrun notarytool history --keychain-profile "$(NOTARY_PROFILE)" >/dev/null || \
		(echo "❌ Notary keychain profile not found or invalid: $(NOTARY_PROFILE)"; \
		 echo "   Create it with: make notary-store-credentials APPLE_ID=<apple-id-email> TEAM_ID=$(TEAM_ID)"; exit 1)
	@echo "✅ Release prerequisites are available"

notary-store-credentials:
	@if [ -z "$(APPLE_ID)" ]; then \
		echo "❌ APPLE_ID is required, for example: make notary-store-credentials APPLE_ID=you@example.com TEAM_ID=VJ345Z9T8T"; \
		exit 1; \
	fi
	@if [ -z "$(TEAM_ID)" ]; then \
		echo "❌ TEAM_ID is required, for example: make notary-store-credentials TEAM_ID=VJ345Z9T8T"; \
		exit 1; \
	fi
	@xcrun notarytool store-credentials "$(NOTARY_PROFILE)" --apple-id "$(APPLE_ID)" --team-id "$(TEAM_ID)"

build-app-release: build-app
	@if [ -z "$(DEVELOPER_ID_APPLICATION)" ]; then \
		echo "❌ DEVELOPER_ID_APPLICATION is required."; \
		exit 1; \
	fi
	@echo "🔏 Re-signing app for Developer ID distribution..."
	@codesign --force --timestamp --options runtime --sign "$(DEVELOPER_ID_APPLICATION)" "$(BUILD_APP)"
	@codesign --verify --deep --strict --verbose=2 "$(BUILD_APP)"
	@./scripts/verify-app-bundle.sh "$(BUILD_APP)"
	@echo "✅ Developer ID app bundle created at $(BUILD_APP)"

# Create distribution DMG
dmg: build-app
	@./scripts/create-dmg.sh
	@./scripts/verify-dmg.sh "$(DMG)"

dmg-release: build-app-release
	@./scripts/create-dmg.sh
	@if [ -z "$(DEVELOPER_ID_APPLICATION)" ]; then \
		echo "❌ DEVELOPER_ID_APPLICATION is required."; \
		exit 1; \
	fi
	@echo "🔏 Signing DMG for distribution..."
	@codesign --force --timestamp --sign "$(DEVELOPER_ID_APPLICATION)" "$(DMG)"
	@codesign --verify --verbose=2 "$(DMG)"
	@./scripts/verify-dmg.sh "$(DMG)"
	@echo "✅ Signed DMG created at $(DMG)"

notarize: check-release-prereqs dmg-release
	@echo "📤 Submitting $(DMG) for notarization..."
	@xcrun notarytool submit "$(DMG)" --keychain-profile "$(NOTARY_PROFILE)" --wait

staple:
	@echo "📎 Stapling notarization ticket to $(DMG)..."
	@xcrun stapler staple "$(DMG)"
	@xcrun stapler validate "$(DMG)"
	@echo "✅ Stapled notarized DMG: $(DMG)"

release-verify:
	@./scripts/verify-app-bundle.sh "$(BUILD_APP)"
	@./scripts/verify-dmg.sh "$(DMG)"
	@codesign --verify --deep --strict --verbose=2 "$(BUILD_APP)"
	@codesign --verify --verbose=2 "$(DMG)"
	@xcrun stapler validate "$(DMG)"
	@spctl -a -vvv -t open --context context:primary-signature "$(DMG)"

release: notarize staple release-verify

# Install app to Applications folder (replaces existing version)
install: build-app
	@echo "🔄 Installing app to Applications folder..."
	@echo "⚠️  Stopping existing app process if needed..."
	@pkill -x "$(EXECUTABLE)" || true
	@pkill -f "$(INSTALL_APP)" || true
	@sleep 1
	@if [ -d "$(INSTALL_APP)" ]; then \
		echo "🗑️  Removing old TwentyGuard version..."; \
		rm -rf "$(INSTALL_APP)"; \
	fi
	@echo "📋 Copying new version to Applications..."
	@cp -R "$(BUILD_APP)" "/Applications/"
	@echo "✅ App installed successfully to $(INSTALL_APP)"
	@echo "💡 You can now launch it from Applications or use 'make launch'"

# Launch the installed app from Applications
launch:
	@echo "🚀 Launching app from Applications..."
	@open "$(INSTALL_APP)"

.PHONY: build run clean build-app verify-app-bundle verify-dmg check-release-prereqs notary-store-credentials build-app-release dmg dmg-release notarize staple release-verify release install launch
