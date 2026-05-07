#!/usr/bin/env bash

set -euo pipefail

APP_PATH="${1:-build/TwentyGuard.app}"
APP_NAME="TwentyGuard"
BUNDLE_ID="com.javengroup.twentyguard"
CORE_RESOURCE_BUNDLE="TwentyGuard_TwentyGuardCore.bundle"
APP_RESOURCE_BUNDLE="TwentyGuard_TwentyGuard.bundle"
INFO_PLIST="${APP_PATH}/Contents/Info.plist"

fail() {
    echo "❌ $1" >&2
    exit 1
}

require_file() {
    local path="$1"
    [ -f "$path" ] || fail "Missing file: $path"
}

require_dir() {
    local path="$1"
    [ -d "$path" ] || fail "Missing directory: $path"
}

require_executable() {
    local path="$1"
    [ -f "$path" ] || fail "Missing executable: $path"
    [ -x "$path" ] || fail "Not executable: $path"
}

plist_value() {
    /usr/libexec/PlistBuddy -c "Print :$1" "$INFO_PLIST" 2>/dev/null || true
}

expect_plist_value() {
    local key="$1"
    local expected="$2"
    local actual
    actual="$(plist_value "$key")"
    [ "$actual" = "$expected" ] || fail "Info.plist $key expected '$expected', got '${actual:-<missing>}'"
}

expect_plist_present() {
    local key="$1"
    local actual
    actual="$(plist_value "$key")"
    [ -n "$actual" ] || fail "Info.plist missing required key: $key"
}

echo "🔎 Verifying app bundle structure: $APP_PATH"

require_dir "$APP_PATH"
require_dir "${APP_PATH}/Contents"
require_dir "${APP_PATH}/Contents/MacOS"
require_dir "${APP_PATH}/Contents/Resources"
require_file "$INFO_PLIST"
require_file "${APP_PATH}/Contents/PkgInfo"
require_executable "${APP_PATH}/Contents/MacOS/${APP_NAME}"

expect_plist_value "CFBundleInfoDictionaryVersion" "6.0"
expect_plist_value "CFBundlePackageType" "APPL"
expect_plist_value "CFBundleExecutable" "$APP_NAME"
expect_plist_value "CFBundleIdentifier" "$BUNDLE_ID"
expect_plist_value "CFBundleName" "$APP_NAME"
expect_plist_value "CFBundleDisplayName" "$APP_NAME"
expect_plist_value "CFBundleIconFile" "AppIcon"
expect_plist_value "CFBundleDevelopmentRegion" "en"
expect_plist_value "LSMinimumSystemVersion" "12.0"
expect_plist_present "CFBundleShortVersionString"
expect_plist_present "CFBundleVersion"
expect_plist_present "LSUIElement"
expect_plist_present "NSHighResolutionCapable"

require_file "${APP_PATH}/Contents/Resources/AppIcon.icns"
require_file "${APP_PATH}/Contents/Resources/version-history.json"
require_file "${APP_PATH}/Contents/Resources/statusbar_icon.png"
require_file "${APP_PATH}/Contents/Resources/statusbar_icon@2x.png"
require_dir "${APP_PATH}/Contents/Resources/${APP_RESOURCE_BUNDLE}"
require_dir "${APP_PATH}/Contents/Resources/${CORE_RESOURCE_BUNDLE}"

for language in en es ja ko zh-Hans; do
    localizable="${APP_PATH}/Contents/Resources/${CORE_RESOURCE_BUNDLE}/${language}.lproj/Localizable.strings"
    if [ ! -f "$localizable" ]; then
        lower_language="$(printf '%s' "$language" | tr '[:upper:]' '[:lower:]')"
        localizable="${APP_PATH}/Contents/Resources/${CORE_RESOURCE_BUNDLE}/${lower_language}.lproj/Localizable.strings"
    fi
    require_file "$localizable"
done

if [ -e "${APP_PATH}/${CORE_RESOURCE_BUNDLE}" ] || [ -e "${APP_PATH}/${APP_RESOURCE_BUNDLE}" ]; then
    fail "SwiftPM resource bundles must live under Contents/Resources, not at the .app root"
fi

if find "$APP_PATH" -name ".DS_Store" -print -quit | grep -q .; then
    fail "App bundle contains .DS_Store"
fi

if find "$APP_PATH" -name "*.xcassets" -type d -print -quit | grep -q .; then
    fail "App bundle contains source asset catalog directories"
fi

if [ -d "${APP_PATH}/Contents/_CodeSignature" ]; then
    require_file "${APP_PATH}/Contents/_CodeSignature/CodeResources"
fi

/usr/sbin/spctl -a -t exec -vv "$APP_PATH" >/dev/null 2>&1 || true

echo "✅ App bundle structure verified"
