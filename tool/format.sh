#!/usr/bin/env bash
# bash tool/format.sh

set -euo pipefail

LINE_LEN=120

if command -v fvm >/dev/null 2>&1; then
  fvm dart format --line-length="$LINE_LEN" .
else
  dart format --line-length="$LINE_LEN" .
fi
