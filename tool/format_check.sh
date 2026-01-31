#!/usr/bin/env bash
set -euo pipefail

LINE_LEN=120

if command -v fvm >/dev/null 2>&1; then
  fvm dart format --line-length="$LINE_LEN" --output=none --set-exit-if-changed .
else
  dart format --line-length="$LINE_LEN" --output=none --set-exit-if-changed .
fi
