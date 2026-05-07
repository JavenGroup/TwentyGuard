#!/usr/bin/env bash

set -euo pipefail

DMG_PATH="${1:-dist/TwentyGuard-v$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist 2>/dev/null || echo 0.0.0).dmg}"
APP_NAME="TwentyGuard"
MOUNT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/twentyguard-dmg-verify.XXXXXX")"

cleanup() {
    hdiutil detach "$MOUNT_DIR" >/dev/null 2>&1 || true
    rmdir "$MOUNT_DIR" >/dev/null 2>&1 || true
}
trap cleanup EXIT

fail() {
    echo "❌ $1" >&2
    exit 1
}

[ -f "$DMG_PATH" ] || fail "Missing DMG: $DMG_PATH"

echo "🔎 Verifying DMG layout: $DMG_PATH"
hdiutil attach -nobrowse -readonly -noverify -mountpoint "$MOUNT_DIR" "$DMG_PATH" >/dev/null

[ -d "${MOUNT_DIR}/${APP_NAME}.app" ] || fail "DMG missing ${APP_NAME}.app"
[ -L "${MOUNT_DIR}/Applications" ] || fail "DMG missing Applications symlink"
[ "$(readlink "${MOUNT_DIR}/Applications")" = "/Applications" ] || fail "Applications symlink must point to /Applications"
[ ! -e "${MOUNT_DIR}/Contents" ] || fail "DMG root must contain ${APP_NAME}.app, not raw app Contents"

"$(dirname "$0")/verify-app-bundle.sh" "${MOUNT_DIR}/${APP_NAME}.app"

echo "✅ DMG layout verified"
