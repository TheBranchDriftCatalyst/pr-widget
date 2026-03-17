#!/usr/bin/env bash
set -euo pipefail

APP_NAME="P-Arr"
BUNDLE_ID="com.catalyst.p-arr"
EXECUTABLE="PArr"
BUILD_DIR="${BUILD_DIR:-.build/debug}"
APP_DIR=".build/${APP_NAME}.app"

# Read version from VERSION file (single source of truth)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VERSION_FILE="${PROJECT_ROOT}/VERSION"
if [[ -f "$VERSION_FILE" ]]; then
    VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
else
    echo "Warning: VERSION file not found, using 0.0.0"
    VERSION="0.0.0"
fi

# Derive build number from git commit count (fallback to 0)
if command -v git &>/dev/null && git rev-parse --git-dir &>/dev/null 2>&1; then
    BUILD_NUMBER="$(git rev-list --count HEAD 2>/dev/null || echo "0")"
else
    BUILD_NUMBER="0"
fi
CONTENTS="${APP_DIR}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"

QUIET=false
for arg in "$@"; do
    case "$arg" in
        --build) swift build 2>&1 ;;
        --quiet) QUIET=true ;;
    esac
done

if [[ ! -f "${BUILD_DIR}/${EXECUTABLE}" ]]; then
    echo "Error: executable not found at ${BUILD_DIR}/${EXECUTABLE}"
    echo "Run 'swift build' first"
    exit 1
fi

# Create bundle structure
mkdir -p "$MACOS" "$RESOURCES"

# Copy executable
cp "${BUILD_DIR}/${EXECUTABLE}" "${MACOS}/${EXECUTABLE}"

# Generate resolved Info.plist
cat > "${CONTENTS}/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleExecutable</key>
    <string>${EXECUTABLE}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026. All rights reserved.</string>
</dict>
</plist>
PLIST

# Copy resource bundles
RESOURCE_BUNDLE="${BUILD_DIR}/PArr_PArr.bundle"
if [[ -d "$RESOURCE_BUNDLE" ]]; then
    cp -R "$RESOURCE_BUNDLE" "$RESOURCES/"
fi

# Copy CHANGELOG.md for in-app changelog viewer
CHANGELOG_FILE="${PROJECT_ROOT}/CHANGELOG.md"
if [[ -f "$CHANGELOG_FILE" ]]; then
    cp "$CHANGELOG_FILE" "$RESOURCES/"
fi

# Sign ad-hoc
codesign --force --sign - --deep "$APP_DIR" 2>/dev/null || true

if [[ "$QUIET" == false ]]; then
    echo "$APP_DIR"
fi
