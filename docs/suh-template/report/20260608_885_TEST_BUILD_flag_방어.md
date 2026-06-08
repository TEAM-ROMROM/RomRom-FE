# 프로덕션 빌드 TEST_BUILD flag 방어 제거

## 개요
프로덕션 빌드 워크플로에서 `secrets.ENV_FILE`에 실수로 `TEST_BUILD=true`가 박혀 들어가더라도 앱이 오염되지 않도록, `.env` 생성 직후 `TEST_BUILD` 줄을 강제 제거하는 방어 코드를 추가했다. (main 직접 반영, 커밋 `795aa26`)

## 배경
`TEST_BUILD=true`는 런타임에 디버그 도구 노출(`main.dart`), AdMob 테스트 광고 ID 사용(`ad_mob_service.dart`)을 활성화한다. Secret 오염 시 프로덕션 빌드가 디버그 도구 노출·테스트 광고로 배포될 위험이 있었다.

## 변경 사항

### 프로덕션 빌드 워크플로 3곳
- `ROMROM-ANDROID-PLAYSTORE-CICD.yaml` (Create .env file / build-android)
- `ROMROM-ANDROID-FIREBASE-CICD.yaml` (Create .env file / build-android) — 이름과 달리 release 서명 + deploy 트리거 = 프로덕션 배포 경로라 포함
- `ROMROM-IOS-TESTFLIGHT.yaml` (Ensure .env file exists / build-ios)

각 워크플로의 `.env` 생성 직후, `^TEST_BUILD` 줄 발견 시 경고 로그를 출력하고 `grep -v '^TEST_BUILD'`로 강제 제거한다.

## 주요 구현 내용
- **빌드 비중단**: flag가 제거되면 앱은 안전하므로 빌드를 중단하지 않고 계속 진행. 경고 로그로 Secret 오염 사실만 알려 사후 수정 유도.
- **플랫폼 무관 동일 코드**: `grep -v` 방식으로 Linux(Android)/macOS(iOS) 모두 동일하게 동작.
- **부분일치 오제거 방지**: `^TEST_BUILD` 앵커로 다른 키 오제거 방지.
- 의존성 0의 인라인 처리.

## 비범위
- `prepare-build` 단계 `.env`는 버전 추출용이라 앱 번들에 미포함 → 방어 대상 제외(YAGNI).
- 테스트 워크플로(`TEST-APK`, `TEST-TESTFLIGHT`)는 `TEST_BUILD` 주입이 정상 동작이므로 미적용.
