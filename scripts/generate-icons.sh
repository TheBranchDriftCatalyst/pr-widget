#!/usr/bin/env bash
set -euo pipefail

# ── generate-icons.sh ─────────────────────────────────────────────────────────
# Generate macOS app icon assets and menu bar icons from source PNGs.
#
# Uses:
#   - Python3 + Pillow for square padding and resizing (preserves transparency)
#   - iconutil for .icns generation
#
# Usage:
#   ./scripts/generate-icons.sh [--variant a|b|all] [--active a|b]
# ──────────────────────────────────────────────────────────────────────────────

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

info()  { echo -e "${BLUE}==>${RESET} ${BOLD}$*${RESET}"; }
ok()    { echo -e "${GREEN}  ✓${RESET} $*"; }
warn()  { echo -e "${YELLOW}  ⚠${RESET} $*"; }
err()   { echo -e "${RED}  ✗${RESET} $*" >&2; }

# ── Defaults ──────────────────────────────────────────────────────────────────
VARIANT="all"
ACTIVE="a"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ICONS_DIR="$PROJECT_ROOT/icons"
ASSETS_DIR="$PROJECT_ROOT/PRWidget/Resources/Assets.xcassets"
BUILD_DIR="$PROJECT_ROOT/.build/icons"

# ── Parse arguments ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --variant)
            VARIANT="${2:?'--variant requires a|b|all'}"
            shift 2
            ;;
        --active)
            ACTIVE="${2:?'--active requires a|b'}"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--variant a|b|all] [--active a|b]"
            echo ""
            echo "Options:"
            echo "  --variant a|b|all   Which variants to generate (default: all)"
            echo "  --active  a|b       Which variant populates AppIcon.appiconset (default: a)"
            exit 0
            ;;
        *)
            err "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Normalize to lowercase
VARIANT=$(echo "$VARIANT" | tr '[:upper:]' '[:lower:]')
ACTIVE=$(echo "$ACTIVE" | tr '[:upper:]' '[:lower:]')

# Validate
if [[ "$VARIANT" != "a" && "$VARIANT" != "b" && "$VARIANT" != "all" ]]; then
    err "Invalid --variant: $VARIANT (must be a, b, or all)"
    exit 1
fi
if [[ "$ACTIVE" != "a" && "$ACTIVE" != "b" ]]; then
    err "Invalid --active: $ACTIVE (must be a or b)"
    exit 1
fi

# ── Check prerequisites ─────────────────────────────────────────────────────
if [[ ! -d "$ICONS_DIR" ]]; then
    err "Source icons directory not found: $ICONS_DIR"
    err "Expected PNG files in icons/ folder"
    exit 1
fi

if ! python3 -c "from PIL import Image" 2>/dev/null; then
    err "Python3 Pillow is required. Install with: pip3 install Pillow"
    exit 1
fi

if ! command -v iconutil &>/dev/null; then
    err "iconutil not found (should be built into macOS)"
    exit 1
fi

# ── macOS app icon sizes ────────────────────────────────────────────────────
# Format: "pointSize_scale_pixelSize"
APP_ICON_SIZES=(
    "16_1x_16"
    "16_2x_32"
    "32_1x_32"
    "32_2x_64"
    "128_1x_128"
    "128_2x_256"
    "256_1x_256"
    "256_2x_512"
    "512_1x_512"
    "512_2x_1024"
)

# ── Python helper: pad to square + resize ────────────────────────────────────
pad_and_resize() {
    local src="$1"
    local dst="$2"
    local size="$3"

    python3 <<PYEOF
from PIL import Image

img = Image.open("$src").convert("RGBA")
w, h = img.size

# Pad to square (centered, transparent background)
side = max(w, h)
square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
offset_x = (side - w) // 2
offset_y = (side - h) // 2
square.paste(img, (offset_x, offset_y))

# Resize to target
resized = square.resize(($size, $size), Image.LANCZOS)
resized.save("$dst", "PNG")
PYEOF
}

# ── Python helper: create menu bar template image ────────────────────────────
# Menu bar icons are rendered as template images (monochrome, alpha-based)
create_menu_bar_icon() {
    local src="$1"
    local dst="$2"
    local size="$3"

    python3 <<PYEOF
from PIL import Image

img = Image.open("$src").convert("RGBA")
w, h = img.size

# Pad to square
side = max(w, h)
square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
offset_x = (side - w) // 2
offset_y = (side - h) // 2
square.paste(img, (offset_x, offset_y))

# Resize to target
resized = square.resize(($size, $size), Image.LANCZOS)
resized.save("$dst", "PNG")
PYEOF
}

# ── Generate Contents.json for app icon ──────────────────────────────────────
generate_app_icon_contents_json() {
    local dir="$1"
    local prefix="$2"

    python3 <<PYEOF
import json, os

images = []
sizes = [16, 32, 128, 256, 512]
for s in sizes:
    for scale, px in [("1x", s), ("2x", s * 2)]:
        filename = f"${prefix}_{s}x{s}@{scale}.png"
        images.append({
            "filename": filename,
            "idiom": "mac",
            "scale": scale,
            "size": f"{s}x{s}"
        })

contents = {
    "images": images,
    "info": {
        "author": "xcode",
        "version": 1
    }
}

path = os.path.join("$dir", "Contents.json")
with open(path, "w") as f:
    json.dump(contents, f, indent=2)
    f.write("\n")
PYEOF
}

# ── Generate Contents.json for menu bar imageset ─────────────────────────────
generate_menu_bar_contents_json() {
    local dir="$1"
    local prefix="$2"

    python3 <<PYEOF
import json, os

images = [
    {
        "filename": f"${prefix}_18x18.png",
        "idiom": "mac",
        "scale": "1x"
    },
    {
        "filename": f"${prefix}_18x18@2x.png",
        "idiom": "mac",
        "scale": "2x"
    }
]

contents = {
    "images": images,
    "info": {
        "author": "xcode",
        "version": 1
    },
    "properties": {
        "template-rendering-intent": "template"
    }
}

path = os.path.join("$dir", "Contents.json")
with open(path, "w") as f:
    json.dump(contents, f, indent=2)
    f.write("\n")
PYEOF
}

# ── Generate .icns file ─────────────────────────────────────────────────────
generate_icns() {
    local variant_letter="$1"
    local iconset_dir="$BUILD_DIR/AppIcon-${variant_letter}.iconset"

    mkdir -p "$iconset_dir"

    local src_dir="$ASSETS_DIR/AppIcon-${variant_letter^^}.appiconset"
    local prefix="icon_${variant_letter}"

    # iconutil expects specific filenames
    local icon_map=(
        "icon_16x16:${prefix}_16x16@1x.png"
        "icon_16x16@2x:${prefix}_16x16@2x.png"
        "icon_32x32:${prefix}_32x32@1x.png"
        "icon_32x32@2x:${prefix}_32x32@2x.png"
        "icon_128x128:${prefix}_128x128@1x.png"
        "icon_128x128@2x:${prefix}_128x128@2x.png"
        "icon_256x256:${prefix}_256x256@1x.png"
        "icon_256x256@2x:${prefix}_256x256@2x.png"
        "icon_512x512:${prefix}_512x512@1x.png"
        "icon_512x512@2x:${prefix}_512x512@2x.png"
    )

    for mapping in "${icon_map[@]}"; do
        local target_name="${mapping%%:*}"
        local source_name="${mapping##*:}"
        cp "$src_dir/$source_name" "$iconset_dir/${target_name}.png"
    done

    local icns_path="$BUILD_DIR/AppIcon-${variant_letter^^}.icns"
    iconutil -c icns -o "$icns_path" "$iconset_dir"
    ok "Generated $icns_path"
}

# ── Generate icons for one variant ───────────────────────────────────────────
generate_variant() {
    local letter="$1"
    local LETTER="${letter^^}"

    # Source files
    local app_icon_src="$ICONS_DIR/p-arr-00${letter}.png"
    local menu_icon_src="$ICONS_DIR/p-arr-01${letter}.png"

    if [[ ! -f "$app_icon_src" ]]; then
        err "App icon source not found: $app_icon_src"
        return 1
    fi

    info "Generating variant ${LETTER} icons..."

    # ── App icon ──────────────────────────────────────────────────────────
    local appiconset_dir="$ASSETS_DIR/AppIcon-${LETTER}.appiconset"
    mkdir -p "$appiconset_dir"

    local prefix="icon_${letter}"

    for entry in "${APP_ICON_SIZES[@]}"; do
        IFS='_' read -r point_size scale pixel_size <<< "$entry"
        local filename="${prefix}_${point_size}x${point_size}@${scale}.png"
        local dst="$appiconset_dir/$filename"

        pad_and_resize "$app_icon_src" "$dst" "$pixel_size"
    done

    generate_app_icon_contents_json "$appiconset_dir" "$prefix"
    ok "App icon set: $appiconset_dir (10 sizes)"

    # ── Menu bar icon ─────────────────────────────────────────────────────
    if [[ -f "$menu_icon_src" ]]; then
        local menubar_dir="$ASSETS_DIR/MenuBarIcon-${LETTER}.imageset"
        mkdir -p "$menubar_dir"

        local menu_prefix="menubar_${letter}"

        create_menu_bar_icon "$menu_icon_src" "$menubar_dir/${menu_prefix}_18x18.png" 18
        create_menu_bar_icon "$menu_icon_src" "$menubar_dir/${menu_prefix}_18x18@2x.png" 36

        generate_menu_bar_contents_json "$menubar_dir" "$menu_prefix"
        ok "Menu bar icon set: $menubar_dir (1x + 2x template)"
    else
        warn "Menu bar source not found: $menu_icon_src (skipping)"
    fi

    # ── App icon preview imageset (for settings UI) ──────────────────────
    local preview_dir="$ASSETS_DIR/AppIconPreview-${LETTER}.imageset"
    mkdir -p "$preview_dir"
    pad_and_resize "$app_icon_src" "$preview_dir/preview_${letter}_128.png" 128
    pad_and_resize "$app_icon_src" "$preview_dir/preview_${letter}_256.png" 256

    python3 <<PYEOF
import json, os

contents = {
    "images": [
        {"filename": "preview_${letter}_128.png", "idiom": "mac", "scale": "1x"},
        {"filename": "preview_${letter}_256.png", "idiom": "mac", "scale": "2x"}
    ],
    "info": {"author": "xcode", "version": 1}
}

with open(os.path.join("$preview_dir", "Contents.json"), "w") as f:
    json.dump(contents, f, indent=2)
    f.write("\n")
PYEOF
    ok "App icon preview: $preview_dir"

    # ── .icns file ────────────────────────────────────────────────────────
    mkdir -p "$BUILD_DIR"
    generate_icns "$letter"
}

# ── Set active variant ───────────────────────────────────────────────────────
set_active_variant() {
    local letter="$1"
    local LETTER="${letter^^}"
    local source_dir="$ASSETS_DIR/AppIcon-${LETTER}.appiconset"
    local target_dir="$ASSETS_DIR/AppIcon.appiconset"

    if [[ ! -d "$source_dir" ]]; then
        err "Cannot set active variant: $source_dir does not exist"
        return 1
    fi

    info "Setting active variant to ${LETTER}..."

    # Clear existing and copy
    rm -rf "$target_dir"
    mkdir -p "$target_dir"
    cp "$source_dir"/*.png "$target_dir/" 2>/dev/null || true

    # Generate Contents.json with standard "icon_" prefix filenames
    # We need to rename or re-reference the files for the default set
    # Simplest: regenerate with the variant's files but using generic names
    local prefix="icon_${letter}"

    python3 <<PYEOF
import json, os

images = []
sizes = [16, 32, 128, 256, 512]
for s in sizes:
    for scale, px in [("1x", s), ("2x", s * 2)]:
        filename = f"${prefix}_{s}x{s}@{scale}.png"
        images.append({
            "filename": filename,
            "idiom": "mac",
            "scale": scale,
            "size": f"{s}x{s}"
        })

contents = {
    "images": images,
    "info": {
        "author": "xcode",
        "version": 1
    }
}

path = os.path.join("$target_dir", "Contents.json")
with open(path, "w") as f:
    json.dump(contents, f, indent=2)
    f.write("\n")
PYEOF

    # Also copy the .icns as the default
    local icns_src="$BUILD_DIR/AppIcon-${LETTER}.icns"
    if [[ -f "$icns_src" ]]; then
        cp "$icns_src" "$BUILD_DIR/AppIcon.icns"
        ok "Default .icns: $BUILD_DIR/AppIcon.icns"
    fi

    ok "Default AppIcon.appiconset populated from variant ${LETTER}"
}

# ── Main ─────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}P-Arr Icon Generator${RESET}"
echo -e "  Variant: ${BLUE}${VARIANT}${RESET}  Active: ${BLUE}${ACTIVE^^}${RESET}"
echo ""

case "$VARIANT" in
    a)
        generate_variant "a"
        ;;
    b)
        generate_variant "b"
        ;;
    all)
        generate_variant "a"
        echo ""
        generate_variant "b"
        ;;
esac

echo ""
set_active_variant "$ACTIVE"

echo ""
echo -e "${GREEN}${BOLD}Done!${RESET} Icon assets generated in:"
echo "  $ASSETS_DIR"
if [[ -d "$BUILD_DIR" ]]; then
    echo "  $BUILD_DIR (icns files)"
fi
echo ""
