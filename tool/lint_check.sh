#!/usr/bin/env bash
# 린트 체크 스크립트
# 사용법: bash tool/lint_check.sh

set -euo pipefail

echo "Running Flutter analyze..."
flutter analyze

echo "Lint check passed!"
