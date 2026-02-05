#!/usr/bin/env bash
# 전체 체크 스크립트 (포맷 + 린트)
# 사용법: bash tool/full_check.sh

set -euo pipefail

echo "=== Full Check ==="

echo ""
echo "1. Format check..."
bash tool/format_check.sh

echo ""
echo "2. Lint check..."
flutter analyze

echo ""
echo "=== All checks passed! ==="
