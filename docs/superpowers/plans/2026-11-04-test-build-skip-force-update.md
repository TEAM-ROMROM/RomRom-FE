# 테스트 빌드 강제 업데이트 예외 Implementation Plan (#996)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 테스트 빌드는 서버 최소 버전과 관계없이 업데이트 안내(강제·권장)를 띄우지 않는다.

**Architecture:** 빌드 시 `--dart-define=IS_TEST_BUILD=true`를 넣는다. `AppVersionRepository`가 이 값을 보고 버전 API를 호출하지 않고 `UpdateType.none`을 돌려준다. 시작 흐름과 복귀 확인이 모두 이 저장소를 거치므로 한 곳에서 처리된다. 값은 테스트 빌드 워크플로 2개에서만 넣는다.

**Tech Stack:** Flutter, Riverpod, GitHub Actions, fastlane

**Spec:** 이슈 #996 본문 + 대화에서 승인된 설계 (디버그 실행은 예외 대상 아님 — 사용자 요청으로 시뮬레이터 1대 검증을 위해 변경)

## Global Constraints

- 값 이름: `IS_TEST_BUILD` (`bool.fromEnvironment`, 기본 false)
- 예외 대상: `IS_TEST_BUILD=true` 빌드만. **`kDebugMode`는 예외 아님** (로컬 디버그에서 강제 업데이트 흐름 테스트 가능해야 함)
- 예외 시 결과: 강제·권장 모두 `UpdateType.none`, 버전 API 호출 안 함
- 스토어 배포 워크플로(`ROMROM-IOS-TESTFLIGHT`, `ROMROM-ANDROID-PLAYSTORE-CICD`, `ROMROM-ANDROID-FIREBASE-CICD`, `ROMROM-ANDROID-CICD`)는 수정하지 않음
- 프로젝트 규칙: `dart format --line-length=120 .` → `flutter analyze` 통과, 명령 앞 `source ~/.zshrc &&`, 주석은 한국어 짧은 구
- **커밋 금지**: 구현자·리뷰어 `git add`/`git commit` 금지

## Review Focus

- 테스트 빌드에서 복귀 확인(`ResumeVersionCheckService`)이 none을 받아 24시간 확인 시각 저장 → 정상(어차피 건너뜀), 문제없음 확인
- `IS_TEST_BUILD`가 `"true"` 외 값(`"1"`, 빈 값)일 때 → `bool.fromEnvironment`는 false. 워크플로는 정확히 `true`를 넣는다
- Android `ROMROM-ANDROID-CICD`도 같은 Fastfile `build` lane을 쓰므로 옵션 없이 호출 시 값이 들어가지 않아야 함
- iOS 테스트 빌드는 `flutter build ios` 후 `xcodebuild archive`를 다시 돌림 → `flutter build ios --dart-define`이 `ios/Flutter/Generated.xcconfig`의 `DART_DEFINES`에 남아 archive에도 적용되는지 확인

---

### Task 1: 테스트 빌드 구분 값 + 저장소 예외

**Files:**
- Create: `lib/utils/app_build_type.dart`
- Modify: `lib/repositories/app_version_repository.dart`
- Test: `test/repositories/app_version_repository_test.dart`

**Interfaces:**
- Produces:
  - `lib/utils/app_build_type.dart`: `const bool isTestBuild = bool.fromEnvironment('IS_TEST_BUILD');` (주석: 테스트 빌드 워크플로 2개가 `--dart-define=IS_TEST_BUILD=true` 전달, 위치 명시)
  - `AppVersionRepository(this._api, {Duration checkTimeout = ..., bool isUpdateCheckSkipped = isTestBuild})`
  - `fetchServerUpdateType()`: `isUpdateCheckSkipped`면 API 호출 없이 `UpdateType.none` 반환 (로그 `[app version] check skipped : test build`)

- [ ] **Step 1: Write the failing tests**
  - `테스트 빌드는 API 호출 없이 none`: `FakeAppVersionApi`에 호출 횟수 `fetchCallCount` 추가, `updateType = UpdateType.force`; `AppVersionRepository(fakeApi, isUpdateCheckSkipped: true)` → `checkUpdateType()` == none, `fetchServerUpdateType()` == none, `fetchCallCount == 0`
  - `일반 빌드는 기존대로 force`: `isUpdateCheckSkipped: false` → force, `fetchCallCount == 1`
- [ ] **Step 2: Run to fail** — `source ~/.zshrc && flutter test test/repositories/app_version_repository_test.dart` → FAIL
- [ ] **Step 3: Implement**
- [ ] **Step 4: Verify** — 테스트 PASS + `source ~/.zshrc && dart format --line-length=120 lib test && flutter analyze` → `No issues found!`

---

### Task 2: 테스트 빌드 워크플로에 값 전달

**Files:**
- Modify: `.github/workflows/ROMROM-IOS-TEST-TESTFLIGHT.yaml` (`flutter build ios --release --no-codesign --no-tree-shake-icons` 줄, 현재 ~481행)
- Modify: `android/fastlane/Fastfile`
- Modify: `.github/workflows/ROMROM-ANDROID-TEST-APK.yaml` (`bundle exec fastlane build --verbose`, 현재 ~430행)

**Interfaces:**
- iOS: `flutter build ios` 인자에 `--dart-define=IS_TEST_BUILD=true` 추가 (주석: 테스트 빌드 > 최소 버전 강제 업데이트 예외 (#996))
- Fastfile: `lane :build do |options|` → `flutter_build(build: 'apk', project_dir: '..', is_test_build: options[:is_test_build])`; `flutter_build`는 `is_test_build`가 truthy면 `--dart-define=IS_TEST_BUILD=true`를 인자에 추가. 옵션 없이 부르면 지금과 같은 명령
- Android 테스트 워크플로: `bundle exec fastlane build is_test_build:true --verbose`
- 그 외 워크플로는 손대지 않음

- [ ] **Step 1: Implement**
- [ ] **Step 2: Verify**
  - `ruby -c android/fastlane/Fastfile` → `Syntax OK`
  - YAML 문법: `python3 -I -c "import yaml,sys;[yaml.safe_load(open(f)) for f in sys.argv[1:]]" .github/workflows/ROMROM-IOS-TEST-TESTFLIGHT.yaml .github/workflows/ROMROM-ANDROID-TEST-APK.yaml` → 오류 없음
  - `grep -n "IS_TEST_BUILD" -r .github/workflows android/fastlane` → 위 3곳만

---

### Task 3 (메인 세션): 시뮬레이터 1대 E2E

- iOS 시뮬레이터 1대, 운영 서버(최소 버전 1.10.129), `--build-name=1.0.0`으로 낮춘 버전
  1. `flutter run --build-name=1.0.0` (값 없음) → 강제 업데이트 화면 캡처
  2. `flutter run --build-name=1.0.0 --dart-define=IS_TEST_BUILD=true` → 강제 업데이트 없이 로그인/홈 진입 캡처
