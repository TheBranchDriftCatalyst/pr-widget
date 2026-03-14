#!/usr/bin/env bash
# Validate conventional commit message format
# See: https://www.conventionalcommits.org/en/v1.0.0/
set -euo pipefail

MSG_FILE="$1"
MSG=$(head -1 "$MSG_FILE")

# Pattern: type(optional-scope): description
PATTERN='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?:\ .+'

if [[ ! "$MSG" =~ $PATTERN ]]; then
    echo "ERROR: Commit message does not follow Conventional Commits format."
    echo ""
    echo "  Expected: <type>[optional scope]: <description>"
    echo "  Got:      $MSG"
    echo ""
    echo "  Types: feat fix docs style refactor perf test build ci chore revert"
    echo "  Example: feat: add version display to header"
    echo "           fix(auth): handle expired token gracefully"
    echo ""
    exit 1
fi
