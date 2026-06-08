# Android 테스트 APK 빌드 실패 - Fastlane multi_json 의존성 누락

## 개요
`@suh-lab app build`로 트리거되는 Android 테스트 APK 빌드의 `Install Fastlane` step에서 `multi_json is not part of the bundle` (`Gem::LoadError`)로 실패하던 문제를 해결했다. 워크플로 Gemfile에 `gem "multi_json"`을 직접 선언해 보강했다. (main 직접 hotfix, 커밋 `4c1e1c9`)

## 변경 사항

### CI 워크플로
- `.github/workflows/ROMROM-ANDROID-TEST-APK.yaml`: Gemfile 생성부에 `gem "multi_json"` 추가.

```diff
-          printf 'source "https://rubygems.org"\ngem "fastlane"\n' > Gemfile
+          printf 'source "https://rubygems.org"\ngem "fastlane"\ngem "multi_json"\n' > Gemfile
```

## 주요 구현 내용
- **원인**: 외부 gem(`google-apis`/`representable`)이 2026년 5월 말경 `multi_json` 의존성을 추가했으나 gemspec에 선언하지 않은 upstream 버그. Gemfile이 버전을 고정하지 않아 깨진 최신 의존성을 받아 실패.
- **대응**: Fastlane 공식도 동일하게 `multi_json`을 직접 의존성으로 추가한 조치를 따름. GitHub Actions 러너 전역 문제(`actions/runner-images#14186`)와 동일 증상.
- `repository_dispatch` 빌드는 main 워크플로 기준으로 동작하므로 main에 직접 hotfix 적용.

## 검증
- hotfix 후 재트리거 시 `Install Fastlane` step 정상 통과, Android APK 빌드 완료(앱 버전 `1.10.84(91702)`, 커밋 `bdfba9f`) 및 iOS TestFlight 빌드도 함께 완료 확인.

## 주의사항
- 앱 동작·다른 step에 영향 없는 안전한 의존성 선언 보강이다.
- upstream gem이 추후 gemspec을 정상화하면 이 명시 선언은 무해하게 중복될 뿐 제거 불필요.
