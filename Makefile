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
	@echo "✅ App bundle created at build/20-20-20.app"

# Create distribution DMG
dmg: build-app
	@./create-dmg.sh

.PHONY: build run clean build-app dmg