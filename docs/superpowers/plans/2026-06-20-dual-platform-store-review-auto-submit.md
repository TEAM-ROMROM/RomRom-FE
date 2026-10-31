# 양 플랫폼(iOS/Android) 스토어 심사 자동 제출 통합 + 1회 배포 실측 검증 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** iOS에 App Store production 심사 자동 제출을 추가하고 거짓 성공을 제거해, 한 번의 `/suh-changelog-deploy` 배포로 iOS·Android 양 플랫폼이 "업로드 → 심사 제출 → (통과 시) 출시"까지 자동 처리되도록 만들고 실측 검증한다.

**Architecture:** Android는 거짓 성공 수정(`19291c7`)이 이미 `origin/main`에 있어 동기화 후 반영 확인만 한다. iOS는 `ROMROM-IOS-TESTFLIGHT.yaml`의 fastlane heredoc에 `deliver`(심사 제출) 단계를 추가하고 `|| echo` 거짓 성공을 제거한다. 검증은 1회 배포로 양 워크플로우를 동시에 돌려 CI 로그 + 콘솔 웹(Play Console / App Store Connect)에서 심사 진입을 실측한다.

**Tech Stack:** GitHub Actions, fastlane(supply / pilot / deliver), Flutter, `/suh-github`(CI 로그·이슈), `/suh-changelog-deploy`(배포), `/browse`(웹 검증).

---

## 작업 전 주의사항

- **CLAUDE.md 절대 규칙**: 사용자 명시 허락 없이 `git commit`/`git add`/`git push` 금지. 이 plan의 commit 단계는 모두 **사용자 승인 후** 실행한다. 서브에이전트에게도 커밋 금지를 명시한다.
- **Skill 우회 금지**: GitHub 작업(이슈/PR/댓글)은 `/suh-github`, commit은 `/suh-commit`, 배포는 `/suh-changelog-deploy`를 거친다.
- **CLI**: 모든 명령 앞에 `source ~/.zshrc &&`.
- **현재 상태**: 로컬 HEAD가 `#922` 브랜치라 Android 3개 옵션이 로컬에 없다(정상). Task 1에서 main 동기화로 해결.

---

## File Structure

| 파일 | 역할 | 변경 |
|------|------|------|
| `android/fastlane/Fastfile.playstore` | Play Store 배포/승급 lane | 변경 없음 (main에 이미 반영). 동기화로 확인만 |
| `.github/workflows/ROMROM-IOS-TESTFLIGHT.yaml` | iOS TestFlight→App Store 배포 워크플로우 | heredoc Fastfile에 `deliver` 추가 + 487줄 `\|\| echo` 제거 + lane/로그 재명명 |
| iOS 신규 GitHub 이슈 | iOS 심사 자동화 추적 (#930 연계) | 생성 |

---

## Task 1: main 동기화 + Android 반영 확인 + 작업 브랜치 생성

**Files:**
- Verify: `android/fastlane/Fastfile.playstore`

- [ ] **Step 1: 현재 작업 손실 방지 확인**

Run:
```bash
source ~/.zshrc && git -C /Users/suhsaechan/Desktop/Programming/project/RomRom-FE status -sb
```
Expected: 현재 `#922` 브랜치. 미커밋 변경이 있으면 사용자에게 알리고 진행 여부 확인(이 plan은 새 브랜치를 origin/main에서 따므로 #922 작업과 분리됨).

- [ ] **Step 2: origin/main 최신화**

Run:
```bash
source ~/.zshrc && cd /Users/suhsaechan/Desktop/Programming/project/RomRom-FE && git fetch origin main
```
Expected: fetch 성공. `origin/main`에 `19291c7`(거짓 성공 수정) 포함.

- [ ] **Step 3: origin/main 기준 작업 브랜치 생성**

브랜치명은 iOS 신규 이슈 번호 확정 후 `YYYYMMDD_#<이슈번호>_iOS_AppStore_심사_자동_제출` 형식으로 만든다(Task 2에서 이슈 생성 후 이 step으로 돌아옴). 임시로 main 기준 체크아웃만 먼저:
```bash
source ~/.zshrc && cd /Users/suhsaechan/Desktop/Programming/project/RomRom-FE && git checkout -b temp_dual_store_review origin/main
```
Expected: `origin/main` 기준 새 브랜치 생성.

- [ ] **Step 4: Android 3개 옵션 반영 확인 (정적 검증)**

Run:
```bash
source ~/.zshrc && grep -n "track_promote_release_status\|changes_not_sent_for_review\|rescue_changes_not_sent_for_review" android/fastlane/Fastfile.playstore
```
Expected: 3줄 모두 출력:
```
track_promote_release_status: 'completed',
changes_not_sent_for_review: false,
rescue_changes_not_sent_for_review: false
```
세 줄이 안 나오면 main 동기화가 안 된 것 — Step 2 재실행.

- [ ] **Step 5: Android는 코드 변경 없음 — 커밋 없이 다음 Task로**

Android는 추가 변경이 없으므로 이 Task에서 커밋하지 않는다. (검증은 Task 5의 실측에서 수행)

---

## Task 2: iOS 신규 이슈 생성 (#930 연계)

**Files:**
- Create: iOS 심사 자동화 GitHub 이슈

- [ ] **Step 1: `/suh-issue` 스킬로 iOS 이슈 작성**

`/suh-issue` 스킬을 호출한다. 이슈 내용 골자:
- 제목(prefix는 템플릿 규칙 따름): `iOS App Store 배포 시 TestFlight 업로드만 되고 심사 자동 제출이 안 되는 문제 + 거짓 성공 제거`
- 본문 핵심:
  - 현재: `ROMROM-IOS-TESTFLIGHT.yaml`이 `pilot()`으로 TestFlight 업로드까지만 하고 App Store production 심사 제출 코드가 없음.
  - 추가 문제: 487줄 `fastlane upload_testflight || echo "...성공적으로 완료됨"` → 업로드 실패해도 워크플로우 초록불(거짓 성공).
  - 해결: `deliver(submit_for_review: true, automatic_release: true, ...)` 추가 + `|| echo` 제거.
  - 연계: Android #930과 같은 "심사까지 자동 + 거짓 성공 제거" 철학. 검증은 #930과 1회 배포로 동시 수행.
  - 본문에 `- https://github.com/TEAM-ROMROM/RomRom-FE/issues/930` 링크 포함.

- [ ] **Step 2: 이슈 번호 확보 후 Task 1 Step 3 브랜치 재명명**

이슈 번호(예: #931)를 받으면 임시 브랜치를 정식 명으로 바꾼다:
```bash
source ~/.zshrc && cd /Users/suhsaechan/Desktop/Programming/project/RomRom-FE && git branch -m temp_dual_store_review 20260620_#<이슈번호>_iOS_AppStore_심사_자동_제출
```
Expected: 브랜치명 변경 완료.

---

## Task 3: iOS — App Store 심사 자동 제출(`deliver`) 추가

**Files:**
- Modify: `.github/workflows/ROMROM-IOS-TESTFLIGHT.yaml:422-447` (heredoc Fastfile)

- [ ] **Step 1: fastlane `deliver` 옵션 공식 확인 (구현 전 검증)**

`deliver`의 `skip_binary_upload`(기존 빌드 선택 동작), `submit_for_review`, `automatic_release`, `force`, `submission_information` 키를 fastlane 공식 문서/소스로 확인한다. 특히 **`pilot`의 `skip_waiting_for_build_processing: true` 때문에 `deliver` 시점에 빌드 처리가 안 끝나 심사 제출이 실패할 수 있는지**를 확인한다.

확인 결과에 따라 둘 중 하나를 택한다:
- (a) `pilot`의 `skip_waiting_for_build_processing`를 `false`로 바꿔 처리 완료를 기다린 뒤 `deliver`.
- (b) `pilot`은 그대로 두고, `deliver` 직전 `app_store_build_number`/빌드 처리 폴링으로 대기.

이 plan은 (a)를 기본으로 한다(가장 단순·확실). 처리 대기가 길어 타임아웃 위험이 있으면 (b)로 전환.

- [ ] **Step 2: heredoc Fastfile 수정 — lane 재명명 + deliver 추가**

`.github/workflows/ROMROM-IOS-TESTFLIGHT.yaml` 422-447줄의 heredoc 블록을 아래로 교체한다. (lane 이름을 `deploy_appstore`로 바꾸고, pilot은 처리 대기하도록 `skip_waiting_for_build_processing: false`, 그 뒤 `deliver` 추가)

```yaml
          cat > fastlane/Fastfile << 'EOF'
          default_platform(:ios)

          platform :ios do
            lane :deploy_appstore do
              api_key = app_store_connect_api_key(
                key_id: ENV["APP_STORE_CONNECT_API_KEY_ID"],
                issuer_id: ENV["APP_STORE_CONNECT_ISSUER_ID"],
                key_filepath: ENV["API_KEY_PATH"]
              )

              # 1) TestFlight 업로드 (심사 제출 전 빌드 처리 완료를 기다린다)
              pilot(
                api_key: api_key,
                ipa: ENV["IPA_PATH"],
                changelog: ENV["RELEASE_NOTES"],
                skip_waiting_for_build_processing: false,  # deliver가 쓸 수 있도록 처리 완료 대기
                distribute_external: false,
                notify_external_testers: false,
                uses_non_exempt_encryption: false  # 암호화 규정 자동 설정
              )
              puts "✅ TESTFLIGHT 업로드 완료!"

              # 2) App Store production 심사 자동 제출 (수동 입력 제거 — 이 작업의 핵심)
              #    메타데이터/스크린샷은 App Store Connect 웹에서 관리 → 빌드만 심사 제출
              deliver(
                api_key: api_key,
                submit_for_review: true,     # 심사 자동 제출
                automatic_release: true,     # 심사 통과 즉시 자동 출시
                force: true,                 # CI 비대화형: HTML 미리보기 확인 건너뜀
                skip_binary_upload: true,    # pilot으로 올린 빌드 사용 (재업로드 안 함)
                skip_metadata: true,         # 메타는 웹 관리
                skip_screenshots: true,      # 스샷은 웹 관리
                precheck_include_in_app_purchases: false,
                submission_information: {
                  add_id_info_uses_idfa: false  # 광고 식별자 미사용 (심사 질문 자동 응답)
                }
              )
              puts "✅ APP STORE 심사 제출 완료!"
            end
          end
          EOF
```

- [ ] **Step 3: YAML 문법 검증**

Run:
```bash
source ~/.zshrc && python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/ROMROM-IOS-TESTFLIGHT.yaml')); print('YAML OK')"
```
Expected: `YAML OK`. 에러 시 heredoc 들여쓰기 확인.

- [ ] **Step 4: deliver 블록 삽입 정적 확인**

Run:
```bash
source ~/.zshrc && grep -n "lane :deploy_appstore\|submit_for_review: true\|automatic_release: true\|skip_binary_upload: true\|APP STORE 심사 제출 완료" .github/workflows/ROMROM-IOS-TESTFLIGHT.yaml
```
Expected: 5줄 모두 출력.

---

## Task 4: iOS — 거짓 성공 제거 + lane 호출부 갱신

**Files:**
- Modify: `.github/workflows/ROMROM-IOS-TESTFLIGHT.yaml:487` 및 인접 step 이름/로그

- [ ] **Step 1: 487줄 `|| echo` 제거 + 새 lane 이름으로 호출**

`.github/workflows/ROMROM-IOS-TESTFLIGHT.yaml` 487줄을 교체한다:
```bash
# 변경 전
          fastlane upload_testflight || echo "⚠️ 권한 에러 발생했지만 업로드는 성공적으로 완료됨"
# 변경 후 (심사 제출까지 포함, 실패 시 정직하게 빨간불)
          fastlane deploy_appstore
```

- [ ] **Step 2: step 이름/로그 문구를 "심사 제출" 반영해 갱신**

같은 파일에서 `Upload to TestFlight with Fastlane`(450줄 부근) step 이름과 `Notify TestFlight Upload Success`(490줄 부근) 로그 문구를 심사 제출을 포함하도록 수정한다. 예:
- step name: `Upload to TestFlight & Submit to App Store`
- 성공 로그: `echo "✅ TestFlight 업로드 + App Store 심사 제출 성공!"`

(문구 변경이므로 정확한 텍스트는 해당 줄을 Read 후 자연스럽게 수정. 동작에는 영향 없음.)

- [ ] **Step 3: `|| echo` / `upload_testflight` 잔존 없음 확인**

Run:
```bash
source ~/.zshrc && grep -n "upload_testflight\|성공적으로 완료됨\|fastlane deploy_appstore" .github/workflows/ROMROM-IOS-TESTFLIGHT.yaml
```
Expected: `fastlane deploy_appstore` 1줄만. 옛 `upload_testflight`/`성공적으로 완료됨`은 없어야 함(heredoc 안 lane 정의 제외 — lane 이름이 deploy_appstore로 바뀌었으므로 둘 다 안 나옴).

- [ ] **Step 4: 최종 YAML 문법 재검증**

Run:
```bash
source ~/.zshrc && python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ROMROM-IOS-TESTFLIGHT.yaml')); print('YAML OK')"
```
Expected: `YAML OK`.

- [ ] **Step 5: 변경 diff 검토 후 사용자 승인 받아 커밋**

Run (diff 확인):
```bash
source ~/.zshrc && git -C /Users/suhsaechan/Desktop/Programming/project/RomRom-FE diff .github/workflows/ROMROM-IOS-TESTFLIGHT.yaml
```
diff를 사용자에게 보여주고 **명시적 커밋 승인**을 받는다. 승인되면 `/suh-commit` 스킬로 커밋(브랜치명에서 이슈 번호 자동 추출). **승인 전 절대 `git add`/`git commit` 금지.**

---

## Task 5: 1회 배포 + 양 플랫폼 실측 검증

**Files:**
- Verify: GitHub Actions 로그, Play Console, App Store Connect

- [ ] **Step 1: App Store Connect 메타 준비 상태 사용자 확인 (배포 전 필수)**

심사 제출은 콘솔에 메타데이터/심사정보가 채워져 있어야 통과한다. 사용자에게 "App Store Connect에 이번 버전 심사 제출에 필요한 정보(스크린샷·설명·심사 메모 등)가 준비됐는지" 확인받는다. 미준비면 사용자가 웹에서 채운 뒤 진행.

- [ ] **Step 2: PR 생성 후 main 머지 (Phase 4~6 표준 flow)**

`/suh-github`로 PR 생성 → 사용자 승인 → main 머지. (CLAUDE.md AgenticFlow Phase 4)

- [ ] **Step 3: `/suh-changelog-deploy`로 1회 배포**

`/suh-changelog-deploy` 스킬 실행. main push → deploy 머지 → **deploy 브랜치 push가 iOS·Android 배포 워크플로우를 동시 트리거**.

- [ ] **Step 4: 양 플랫폼 CI 로그 실측 (`/suh-github actions`)**

`/suh-github` actions로 두 run을 추적한다:
- **Android** (`Android-PlayStore-Internal-Deploy`): production 승급 step에서 `changesNotSentForReview` rescue 문구가 **안 뜨는지** 확인. 승급이 에러 없이 끝나거나, 안 되면 **실패(빨간불)로 표면화**됐는지 확인.
- **iOS** (`Project-iOS-TestFlight-Deploy`): `deliver` 심사 제출 step 성공 로그(`✅ APP STORE 심사 제출 완료!`) 확인. 실패 시 `|| echo` 없이 빨간불로 드러나는지 확인.

Expected: 둘 다 success이면서 로그에 심사 제출 흔적이 있음. 또는 실패면 정직하게 빨간불(거짓 성공 아님).

- [ ] **Step 5: Play Console 웹 실측 (`/browse`)**

`/browse`로 Play Console 접근(로그인 막히면 `handoff`로 사용자 직접 로그인):
- URL: `https://play.google.com/console/u/0/developers/4736601601401567973/app/4972112751122062243/tracks/production`
- 확인: 해당 버전이 프로덕션 트랙에 **"검토 중"**으로 진입했는지.
- 스크린샷 저장 후 Read로 사용자에게 표시.

- [ ] **Step 6: App Store Connect 웹 실측 (`/browse`)**

`/browse`로 App Store Connect 접근(로그인 막히면 `handoff`):
- 확인: 해당 버전이 **"심사 대기 중(Waiting for Review)"** 또는 "심사 중(In Review)"으로 진입했는지.
- 스크린샷 저장 후 Read로 사용자에게 표시.

- [ ] **Step 7: 사용자 최종 검증 요구**

두 스크린샷(Play Console "검토 중" + App Store Connect "심사 대기")을 사용자에게 제시하고 **"양쪽 모두 심사에 실제 진입한 게 맞는지" 최종 확인**을 받는다.

- [ ] **Step 8: 결과를 이슈 댓글에 기록 (`/suh-github`)**

`/suh-github`로:
- #930 댓글: Android 실측 결과(로그 + Play Console 스크린샷 요약), 체크리스트 갱신.
- iOS 신규 이슈 댓글: iOS 실측 결과(로그 + App Store Connect 스크린샷 요약).

---

## 검증 실패 시 대응 (분기)

- **Android 거짓 성공 재발** (rescue 문구가 또 뜸): `rescue_changes_not_sent_for_review: false`가 반영됐는데도 뜨면 권한/메타 문제. 로그의 실제 Google API 에러 메시지로 재진단.
- **iOS deliver 실패** ("빌드 처리 중"): Task 3 Step 1의 (b)안(빌드 처리 폴링 대기)으로 전환 후 재배포.
- **iOS deliver 실패** (메타 미충족): App Store Connect에서 누락 항목 채운 뒤 재배포.
- **콘솔 로그인 차단** (봇 감지): 자동 로그인 포기, `/browse handoff`로 사용자 직접 로그인 후 `resume`.

---

## 보안 메모

검증 과정에서 채팅에 노출된 Google 계정 자격증명은 작업 완료 후 **비밀번호 변경**을 권고한다.
