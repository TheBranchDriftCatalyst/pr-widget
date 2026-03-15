#!/usr/bin/env bash
set -euo pipefail

# ── Config ──────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VERSION="$(tr -d '[:space:]' < "$PROJECT_ROOT/VERSION")"

APP_NAME="P-Arr"
APP_DIR="$PROJECT_ROOT/.build/${APP_NAME}.app"
ZIP_NAME="${APP_NAME}-${VERSION}.zip"
ZIP_PATH="$PROJECT_ROOT/.build/${ZIP_NAME}"

# ── Build release ───────────────────────────────────────────────
echo "==> Building release..."
cd "$PROJECT_ROOT"
swift build -c release 2>&1

# ── Bundle .app ─────────────────────────────────────────────────
echo "==> Bundling .app..."
BUILD_DIR=.build/release "$SCRIPT_DIR/bundle.sh"

# ── Create .zip ─────────────────────────────────────────────────
echo "==> Packaging ${ZIP_NAME}..."
rm -f "$ZIP_PATH"
# ditto preserves code signatures, extended attributes, and resource forks
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"

# ── Compute SHA256 ──────────────────────────────────────────────
SHA256=$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')

echo ""
echo "==> Package complete"
echo "    File: .build/${ZIP_NAME}"
echo "    Size: $(du -h "$ZIP_PATH" | awk '{print $1}')"
echo "    SHA256: ${SHA256}"
