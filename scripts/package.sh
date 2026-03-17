#!/usr/bin/env bash
set -euo pipefail

# ── Config ──────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/_brand.sh"
VERSION="$(tr -d '[:space:]' < "$PROJECT_ROOT/VERSION")"

APP_NAME="P-Arr"
APP_DIR="$PROJECT_ROOT/.build/${APP_NAME}.app"
ZIP_NAME="${APP_NAME}-${VERSION}.zip"
ZIP_PATH="$PROJECT_ROOT/.build/${ZIP_NAME}"

# ── Build release ───────────────────────────────────────────────
step "Building release..."
cd "$PROJECT_ROOT"
BUILD_START=$SECONDS
BUILD_OUTPUT=$(swift build -c release 2>&1)
BUILD_EXIT=$?
BUILD_TIME=$(( SECONDS - BUILD_START ))
if [[ $BUILD_EXIT -ne 0 ]]; then
  # Show only error lines on failure
  echo "$BUILD_OUTPUT" | grep -E "^.*error:" || true
  err "Build failed"
  exit 1
fi
done_step "Built release ${DIM}(${BUILD_TIME}s)${RESET}"

# ── Bundle .app ─────────────────────────────────────────────────
step "Bundling ${APP_NAME}.app..."
BUILD_DIR=.build/release "$SCRIPT_DIR/bundle.sh" --quiet
done_step "Bundled ${CYAN}${APP_NAME}.app${RESET}"

# ── Create .zip ─────────────────────────────────────────────────
step "Packaging ${ZIP_NAME}..."
rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"
SHA256=$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')
SIZE=$(du -h "$ZIP_PATH" | awk '{print $1}')
done_step "Packaged ${CYAN}${ZIP_NAME}${RESET} ${DIM}(${SIZE})${RESET}"
info "SHA256: ${DIM}${SHA256}${RESET}"
