#!/bin/bash
# Firebase Hosting 배포 스크립트
# .env의 ANDROID_SHA256_FINGERPRINT를 assetlinks.json에 주입 후 배포

set -e

# .env에서 ANDROID_SHA256_FINGERPRINT만 읽기
if [ ! -f ".env" ]; then
  echo "❌ .env 파일이 없습니다"
  exit 1
fi

ANDROID_SHA256_FINGERPRINT=$(grep '^ANDROID_SHA256_FINGERPRINT=' .env | cut -d '=' -f2-)

if [ -z "$ANDROID_SHA256_FINGERPRINT" ]; then
  echo "❌ .env에 ANDROID_SHA256_FINGERPRINT가 없습니다"
  exit 1
fi

# assetlinks.json 생성 (env 치환)
ASSETLINKS_TEMPLATE="public/.well-known/assetlinks.json"
ASSETLINKS_OUT="public/.well-known/assetlinks.json"

sed "s|\${ANDROID_SHA256_FINGERPRINT}|$ANDROID_SHA256_FINGERPRINT|g" \
  "$ASSETLINKS_TEMPLATE" > "$ASSETLINKS_OUT.tmp" && mv "$ASSETLINKS_OUT.tmp" "$ASSETLINKS_OUT"

echo "✅ assetlinks.json 생성 완료"

# Firebase Hosting 배포
firebase deploy --only hosting

echo "✅ Firebase Hosting 배포 완료"
