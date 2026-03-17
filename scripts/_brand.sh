#!/usr/bin/env bash
# ── Catalyst Brand Output ───────────────────────────────────────
# Shared formatting for all P-Arr scripts.
# Source this at the top of any script: source "$(dirname "$0")/_brand.sh"

# ANSI color codes
CYAN='\033[36m'
MAGENTA='\033[35m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Brand bar
BAR="${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# Print a step indicator: ▸ Building release...
step() {
  printf "  ${CYAN}▸${RESET} %b\n" "$1"
}

# Print a completed step: ✓ Built release (16s)
done_step() {
  printf "  ${GREEN}✓${RESET} %b\n" "$1"
}

# Print an info line (indented, dim)
info() {
  printf "    %b\n" "$1"
}

# Print an error line
err() {
  printf "  ${RED}✗${RESET} %b\n" "$1" >&2
}

# Print the branded header
header() {
  echo ""
  printf "  ${BOLD}${CYAN}P-Arr${RESET} ${DIM}│${RESET} %b\n" "$1"
  echo -e "  ${BAR}"
}

# Print the branded footer
footer() {
  echo -e "  ${BAR}"
  printf "  ${GREEN}${BOLD}✓${RESET} ${BOLD}%b${RESET}\n" "$1"
  if [[ -n "${2:-}" ]]; then
    info "${DIM}${2}${RESET}"
  fi
  echo ""
}
