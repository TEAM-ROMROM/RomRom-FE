# 양 플랫폼(iOS/Android) 스토어 심사 자동 제출 통합 + 1회 배포 실측 검증

- 작성일: 2026-06-20
- 관련 이슈: [#930](https://github.com/TEAM-ROMROM/RomRom-FE/issues/930) (Android), iOS 신규 이슈(작성 예정)
- 상태: 설계 승인 완료, 구현 대기

## 1. 배경 / 문제 정의

이미 production으로 출시 중인 앱이다. 매 릴리스마다 **각 플랫폼 콘솔에서 심사를 수동으로 입력/제출**해야 하는 게 핵심 불편이다. 테스트 배포와 바이너리 업로드는 지금도 자동으로 잘 되지만, **"심사 요청(제출)"까지가 자동이 아니다.** 목표는 양 플랫폼 모두 "업로드 → 심사 제출 → (통과 시) 출시"를 한 번의 배포로 자동 처리하는 것.

### 1.1 진단 결과 (전수 확인)

| 항목 | Android (Play Store) | iOS (App Store) |
|------|----------------------|-----------------|
| 트리거 | `deploy` push / 죽은 changelog 트리거 / 수동 | 동일 |
| 바이너리 업로드 | ✅ AAB → internal 트랙 | ✅ IPA → TestFlight (`pilot`) |
| 심사 자동 제출 | ⚠️ promote lane 존재, 단 "거짓 성공" 버그 → 수정 커밋 `19291c7`이 **이미 main에 있음**, 실측 미검증 | ❌ **아예 없음** — `pilot()`으로 TestFlight 업로드까지만, App Store 심사 제출 코드 없음 |
| 거짓 성공 위험 | `deploy_internal`은 `\|\| echo` 없음 → 실패 시 정직하게 빨간불 | 🔴 `ROMROM-IOS-TESTFLIGHT.yaml` 487줄 `fastlane upload_testflight \|\| echo "...성공적으로 완료됨"` → 업로드 실패해도 무조건 초록불 |

### 1.2 배포 트리거 메커니즘 (확정)

```
/suh-changelog-deploy
   └─ git push origin main ─→ [AUTO UPDATE PROJECT CHANGELOG] 워크플로우
   └─ main→deploy PR + automerge ─→ deploy 브랜치 push
          └─ branches:["deploy"] 트리거
                 ├─→ Android-PlayStore-Internal-Deploy
                 └─→ Project-iOS-TestFlight-Deploy
```

**핵심: 배포 1회 = iOS + Android 동시 실행.** 따라서 검증도 한 번의 `/suh-changelog-deploy`로 양쪽을 동시에 본다.

**부수 발견 (이번 범위 제외)**: 두 배포 워크플로우의 `workflow_run: ["CHANGELOG 자동 업데이트"]`는 실제 워크플로우 이름(`AUTO UPDATE PROJECT CHANGELOG`)과 불일치해 **죽은 트리거**다. deploy 브랜치 push 경로가 살아있어 실제 배포에는 지장 없다. **사용자 결정에 따라 이번에는 건드리지 않는다** (명확한 연결 경로가 하나라 오히려 안전).

## 2. 목표 / 비목표

### 목표
- iOS: TestFlight 업로드 후 **App Store production 심사 자동 제출 + 심사 통과 시 자동 출시** 추가.
- iOS: `|| echo` 거짓 성공 제거 → 업로드/심사 실패가 워크플로우 빨간불로 표면화.
- Android: 로컬을 main에 동기화해 이미 머지된 거짓 성공 수정(`19291c7`)이 반영됨을 확인. (추가 코드 변경 없음)
- **1회 배포로 양 플랫폼 심사 제출이 실제로 일어나는지 실측 검증** (CI 로그 + 콘솔 웹).

### 비목표
- iOS 메타데이터/스크린샷/심사정보의 코드(repo) 관리 → **App Store Connect 웹에서 수동 관리.** 워크플로우는 빌드만 심사에 제출(`skip_metadata`/`skip_screenshots`).
- 죽은 `workflow_run` 트리거 이름 정리.
- Android 코드 추가 변경 (이미 main에 완료).
- 단계적 출시(rollout) 비율 변경 등 출시 정책 변경.

## 3. 코드 변경 설계

### 3.1 Android — 변경 없음, 동기화만
수정 커밋 `19291c7`이 이미 `origin/main`에 있다. 현재 로컬 HEAD가 #922 브랜치라 그 이전 코드를 보고 있었을 뿐. main으로 동기화하면 `android/fastlane/Fastfile.playstore`의 `promote_internal_to_production` lane에 아래 3개 옵션이 반영되어 있어야 한다(반영 확인이 작업의 전부):
```ruby
track_promote_release_status: 'completed',   # 프로덕션 릴리스 completed 명시
changes_not_sent_for_review: false,          # 심사로 전송 의도 명시
rescue_changes_not_sent_for_review: false    # 거짓 성공 차단: 실패 시 워크플로우 실패
```

### 3.2 iOS — App Store 심사 자동 제출 추가
파일: `.github/workflows/ROMROM-IOS-TESTFLIGHT.yaml`, heredoc Fastfile(현재 426-446줄).

`pilot()`(TestFlight 업로드) **다음**에 `deliver`로 App Store production 심사 제출 단계 추가. 메타/스크린샷은 웹에서 관리하므로 빌드만 심사에 제출:
```ruby
# TestFlight 업로드(pilot) 후 → App Store production 심사 자동 제출
# 메타데이터/스크린샷은 App Store Connect 웹에서 관리 → 빌드만 심사 제출
deliver(
  api_key: api_key,
  submit_for_review: true,         # 심사 자동 제출 (수동 입력 제거 — 이 작업의 핵심)
  automatic_release: true,         # 심사 통과 즉시 자동 출시
  force: true,                     # CI 비대화형: HTML 미리보기 확인 건너뜀
  skip_binary_upload: true,        # pilot으로 이미 올린 빌드 사용 (재업로드 안 함)
  skip_metadata: true,             # 메타는 웹 관리
  skip_screenshots: true,          # 스샷은 웹 관리
  precheck_include_in_app_purchases: false,
  submission_information: {        # 심사 질문(IDFA 등) 자동 응답
    add_id_info_uses_idfa: false
  }
)
```
> 구현 시: fastlane `deliver` 공식 옵션을 소스로 재확인한다(특히 `skip_binary_upload`가 "기존 빌드 선택"으로 동작하는지, `submission_information` 필수 키). `pilot`의 `skip_waiting_for_build_processing: true` 때문에 `deliver` 시점에 빌드 처리가 안 끝났을 수 있다 → **`deliver`가 처리 완료를 기다리도록** 빌드 처리 대기 로직 또는 옵션 보강이 필요한지 구현 단계에서 검증한다. (이게 iOS 자동화의 핵심 리스크)

### 3.3 iOS — 거짓 성공 제거
파일: `.github/workflows/ROMROM-IOS-TESTFLIGHT.yaml` 487줄.
```bash
# 변경 전
fastlane upload_testflight || echo "⚠️ 권한 에러 발생했지만 업로드는 성공적으로 완료됨"
# 변경 후 (심사 제출까지 포함한 lane 실행, 실패 시 정직하게 빨간불)
fastlane upload_testflight
```
lane 이름은 업로드+심사를 모두 포함하게 바뀌므로 적절히 재명명(예: `deploy_appstore`)할 수 있다. 단계 이름/로그 문구도 "심사 제출"을 반영해 수정.

## 4. 실측 검증 절차 (배포 1회 후)

`/suh-changelog-deploy` 1회 실행 → 양 배포 워크플로우가 동시에 돈다. Claude가 양쪽을 추적한다.

### 4.1 CI 로그 검증 (Claude가 `/suh-github actions`로)
- **Android**: `changesNotSentForReview` rescue 문구가 **안 뜨는지** + production 승급 step이 에러 없이 끝나거나, 안 되면 **실패로 표면화**되는지.
- **iOS**: `deliver` 심사 제출 step 성공 로그 + `|| echo` 없이 실패가 빨간불로 드러나는지.

### 4.2 웹 콘솔 검증 (Claude가 `/browse`로, 사용자 자격증명 자동 로그인 → 막히면 `handoff`)
- **Android**: Play Console → 테스트 및 출시 → 프로덕션 트랙 → 해당 버전이 **"검토 중"**으로 실제 진입했는지 스크린샷.
  - 진입 URL: `https://play.google.com/console/.../app/.../tracks/production`
- **iOS**: App Store Connect → 앱 → 버전 → **"심사 대기 중(Waiting for Review)"** 진입 스크린샷.
- 두 스크린샷을 사용자에게 제시 → **사용자가 최종 눈으로 확인**(검증 요구).

> 보안: Play Console/App Store Connect는 Google/Apple 로그인 벽이 있다. 자동 로그인은 봇 차단/추가 인증 가능성이 있어, 실패 시 즉시 `handoff`(사용자 직접 로그인)로 전환한다. 검증 후 채팅에 노출된 자격증명은 변경을 권고한다.

### 4.3 검증 결과 기록
- Android 결과 → #930 이슈 댓글 (체크리스트 갱신).
- iOS 결과 → iOS 신규 이슈 댓글.
- 검증된 형태는 추후 템플릿(SUH-DEVOPS-TEMPLATE #399)에 이식(이슈 #930 명시 항목, 별도 후속).

## 5. 리스크 / 미해결 가설

1. **iOS 빌드 처리 대기**: `pilot`이 처리 완료를 안 기다리고(`skip_waiting_for_build_processing: true`) 끝나면, 직후 `deliver`가 "심사 제출할 빌드가 아직 처리 중"이라 실패할 수 있다. → 구현 시 처리 대기 보강 필요 여부 검증.
2. **App Store Connect 메타 미충족**: 심사 제출은 메타데이터/심사정보가 콘솔에 채워져 있어야 통과한다. 웹 관리 전제이므로, **검증 배포 전 콘솔에 현재 버전 메타가 준비됐는지 사용자 확인** 필요.
3. **첫 자동 심사 제출의 부작용**: 잘못 제출되면 실제 심사 큐에 들어간다. 검증 배포는 "진짜 올릴 버전"으로 하되, 문제가 보이면 콘솔에서 심사 제출 취소 가능함을 인지.
4. **거짓 성공 제거의 역효과**: 그동안 `|| echo`로 가려졌던 기존 권한/처리 에러가 이제 빨간불로 드러날 수 있다. 이는 버그가 아니라 **숨겨졌던 실패의 표면화**이며 의도된 동작.

## 6. 작업 순서 (구현 단계 개요)

1. 로컬을 `origin/main`에 동기화 → Android 3개 옵션 반영 확인.
2. iOS Fastfile에 `deliver` 심사 제출 추가 + lane 재명명.
3. iOS 487줄 `|| echo` 제거.
4. iOS 신규 이슈 생성(#930 연계).
5. 사용자 승인 후 commit (`/suh-commit`).
6. App Store Connect 메타 준비 상태 사용자 확인.
7. `/suh-changelog-deploy` 1회 배포.
8. 양 플랫폼 CI 로그 실측 (Claude).
9. 양 플랫폼 콘솔 웹 실측 + 스크린샷 → 사용자 최종 확인.
10. 결과를 각 이슈 댓글에 기록.

## 7. 후속: SUH-DEVOPS-TEMPLATE 이식 (검증 성공 시에만)

이 RomRom CICD 코드는 `SUH-DEVOPS-TEMPLATE`(Flutter 배포 템플릿)에서 파생됐다. **검증이 성공하면** 검증된 변경을 템플릿에 이식한다(이슈 #930 명시 항목 + SUH-DEVOPS-TEMPLATE #399). **검증 실패면 템플릿은 건드리지 않는다.**

템플릿은 (a) 내부 flutter util 마법사(`playstore-wizard`/`testflight-wizard`)와 (b) `integrator.sh`/`.ps1`로 쌩기본 템플릿을 설치하는 구조다. 따라서 이식 대상은 "마법사가 생성하는 템플릿 원본"과 "워크플로우 원본" 양쪽이다.

### 파일 매핑 (RomRom → 템플릿)

| RomRom (검증 대상) | SUH-DEVOPS-TEMPLATE (이식 대상) |
|---|---|
| `.github/workflows/ROMROM-IOS-TESTFLIGHT.yaml` (deliver 추가 + `\|\| echo` 제거) | `.github/workflows/project-types/flutter/PROJECT-FLUTTER-IOS-TESTFLIGHT.yaml` + `.github/util/flutter/testflight-wizard/templates/Fastfile` |
| `android/fastlane/Fastfile.playstore` (3개 옵션) | `.github/util/flutter/playstore-wizard/templates/Fastfile.playstore.template` + `.github/workflows/project-types/flutter/PROJECT-FLUTTER-ANDROID-PLAYSTORE-CICD.yaml` |

### 이식 시 주의
- 템플릿 파일은 **플레이스홀더/변수 치환**(예: 패키지명·앱ID)을 쓸 수 있으므로, RomRom의 하드코딩 값을 그대로 복붙하지 말고 템플릿의 변수 규칙에 맞춰 치환한다.
- iOS Fastfile은 RomRom에선 워크플로우 heredoc 인라인이지만, 템플릿에선 별도 `Fastfile`로 분리돼 있다 → 동일 lane 로직을 템플릿 구조에 맞게 배치.
- 이식은 **별도 작업(별도 이슈/PR)**으로 진행한다. 이 spec/plan의 범위는 RomRom 검증까지다.
