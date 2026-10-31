# Flutter 배포 마법사 가이드 개선 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development 또는 superpowers:executing-plans 로 task별 구현. 체크박스(`- [ ]`)로 추적.

**Goal:** Flutter 배포 마법사(testflight-wizard, playstore-wizard)가 처음 배포하는 사용자에게 "빌드→스토어 업로드→(심사 통과 후) 자동 심사 전환" 전체 flow를 UI와 템플릿 주석으로 명확히 가이드하도록 개선한다.

**Architecture:** 마법사는 `.sh`/`.ps1` 셋업 스크립트가 실제 파일을 생성/수정한다. 따라서 **사용자가 값을 선택/입력하는 것은 셋업 실행 전 입력 단계**, **단순 안내는 완료 단계**에 둔다. 배포 모드(store_only/store_prepare/store_submit)는 워크플로우 ENV/repo variable로 제어되며 셋업 스크립트가 파일에 박는 값이 아니므로 마법사에서는 **완료 단계 안내**로 다룬다.

**Tech Stack:** HTML/Tailwind(CDN)/Vanilla JS 마법사, fastlane(Ruby Fastfile), bash/powershell setup 스크립트.

## Global Constraints

- 프로젝트 루트: `D:\0-suh\project\RomRom-FE`. 마법사: `.github/util/flutter/`
- iOS 로케일 디렉토리는 `ko`만 유효(ko-KR 무효 — `Unsupported directory name`). 추가는 `DELIVER_LOCALES` ENV.
- 배포 모드 3종(양 플랫폼 공통): `store_only`(테스트만) / `store_prepare`(제출 직전, 사람이 버튼) / `store_submit`(완전 자동).
- 개인정보(연락처·데모계정) 코드/YAML 하드코딩 금지. ASC 기존값 보존.
- 커밋에 AI/Claude 흔적 금지. 커밋은 사용자 승인 후에만. push도 명시 요청 시.
- 운영 워크플로우(인라인 Fastfile) 수정 시 wizard 템플릿도 동기화.
- **마법사 원칙: 입력 필요 = 입력 단계 / 안내만 = 완료 단계.**

---

## 선행 컨텍스트 — 이미 완료된 운영 작업 (재작업 금지, 참고용)

- iOS `.github/workflows/ROMROM-IOS-TESTFLIGHT.yaml`: deliver 6개 버그 수정(app_identifier/app_version/build_number/whatsNew 절대경로/ko 로케일/Notes 초기화) + 3모드. **실측 검증 완료(1.10.104 Waiting for Review).**
- Android `android/fastlane/Fastfile.playstore` + `ROMROM-ANDROID-PLAYSTORE-CICD.yaml`: 3모드 + rescue_changes_not_sent_for_review:false. 검증 완료.
- 문서: 이슈 #934(가이드)/#930/#931, `docs/suh-template/report/20260622_930_931_*.md`.

## 이 plan 시작 시점의 미커밋 상태 (main 브랜치)

이미 수정됐으나 아직 커밋 안 된 파일 5개 — Task 5에서 함께 커밋:
- `playstore-wizard/playstore-wizard.js` — 죽은 함수 `generateSetupCommand()` 제거 완료
- `playstore-wizard/templates/Fastfile.playstore.template` — 3모드 + 신규앱 가이드 주석 완료
- `testflight-wizard/templates/Fastfile` — 주석 옛 경로명 수정 완료
- `testflight-wizard/testflight-wizard-setup.sh` — help 예시 경로 정확화 완료
- `testflight-wizard/testflight-wizard.html` — init placeholder 경로 + 생성파일 목록(Appfile 제거) 수정 완료

> **다른 세션 작업자:** 위 5개는 이미 됨. `git status`로 확인 후 Task 3(완료단계 안내카드)·Task 4(템플릿 주석)만 새로 하면 된다. Task 1·2는 검증만.

## File Structure

| 파일 | 책임 | 이 plan |
|------|------|---------|
| `testflight-wizard/testflight-wizard.html` | iOS 마법사 9단계 UI | step9 완료에 안내카드 추가 |
| `playstore-wizard/playstore-wizard.html` | Android 마법사 7단계 UI | step7 완료에 안내카드 보강 |
| `testflight-wizard/templates/Fastfile` | iOS Fastfile 템플릿 | 옵션별 가이드 주석 |
| `testflight-wizard/templates/Gemfile` | iOS Gemfile 템플릿 | 의존성 주석 |
| `playstore-wizard/templates/Fastfile.playstore.template` | Android 템플릿 | (완료) 검증만 |
| `playstore-wizard/playstore-wizard.js` | Android 마법사 로직 | (완료) 검증만 |

---

### Task 1: 템플릿/setup 버그 수정 검증 (이미 적용됨 — 확인만)

**Files:** Verify only — testflight html, testflight templates/Fastfile, setup.sh, playstore template

- [ ] **Step 1:** Run `cd .github/util/flutter && grep -rn "flutter-ios-testflight-init\|ios/fastlane/Appfile" testflight-wizard/` → Expected: 결과 없음
- [ ] **Step 2:** Run `grep -c "store_prepare\|promote_status" .github/util/flutter/playstore-wizard/templates/Fastfile.playstore.template` → Expected: >0
- [ ] **Step 3:** Run `grep -c "Draft App\|store_only\|최초 배포" .github/util/flutter/playstore-wizard/templates/Fastfile.playstore.template` → Expected: >0

---

### Task 2: playstore 죽은 함수 제거 검증 (이미 적용됨 — 확인만)

**Files:** Verify only — playstore-wizard.js, playstore-wizard.html

**Interfaces:** setup 명령은 `generateKeystoreCreationCommand()`가 `#keystoreCreationCommandText`에 표시(정상 경로).

- [ ] **Step 1:** Run `grep -c "function generateSetupCommand" .github/util/flutter/playstore-wizard/playstore-wizard.js` → Expected: 0
- [ ] **Step 2:** Run `grep -c "keystoreCreationCommandText" .github/util/flutter/playstore-wizard/playstore-wizard.js` → Expected: >0
- [ ] **Step 3:** Run `grep -c "keystoreCreationCommandText" .github/util/flutter/playstore-wizard/playstore-wizard.html` → Expected: >=1

---

### Task 3: 완료단계 "배포 모드 + 출시 로드맵" 안내카드 추가 (핵심 신규)

**Files:**
- Modify: `testflight-wizard/testflight-wizard.html` — step9 완료 메시지(line ~1561 `🎉 모든 설정이 완료` 의 `</div>`) 직후 삽입
- Modify: `playstore-wizard/playstore-wizard.html` — step7 line ~1840 `🚀 설정 완료 후 다음 단계` 근처 삽입

**Interfaces:** 정적 안내 카드(JS 불필요). 사용자가 완료화면에서 배포 모드 3종·출시 로드맵·모드 변경 위치를 읽음.

- [ ] **Step 1: testflight step9 완료 메시지 `</div>` 직후 카드 삽입.** 삽입할 HTML은 plan 부록 A(아래) 참조. iOS 용어(TestFlight, App Store Connect, Add for Review, IOS_DEPLOY_MODE, ios/fastlane/Fastfile).
- [ ] **Step 2: 검증** Run `python -c "from html.parser import HTMLParser as H; p=H(); p.feed(open('.github/util/flutter/testflight-wizard/testflight-wizard.html',encoding='utf-8').read()); print('OK')"` → Expected: OK
- [ ] **Step 3: playstore step7 `🚀 설정 완료 후 다음 단계` 블록 근처에 카드 삽입.** 부록 B 참조. Android 용어(internal 트랙, production draft, Play Console "출시 시작", ANDROID_DEPLOY_MODE, android/fastlane/Fastfile.playstore).
- [ ] **Step 4: 검증** Run `python -c "from html.parser import HTMLParser as H; p=H(); p.feed(open('.github/util/flutter/playstore-wizard/playstore-wizard.html',encoding='utf-8').read()); print('OK')"` → Expected: OK

---

### Task 4: 템플릿 옵션별 가이드 주석 보강 (testflight Fastfile + Gemfile)

**Files:**
- Modify: `testflight-wizard/templates/Fastfile` — `platform :ios do` 위 헤더 주석에 배포모드 3종/신규앱 최초 수동제출/로케일 ko/개인정보 미하드코딩 설명 추가 (부록 C)
- Modify: `testflight-wizard/templates/Gemfile` — fastlane 2.228·multi_json 이유 주석 (부록 D)

**Interfaces:** 템플릿 받은 사람이 주석만 보고 옵션 의미·수정법 이해.

- [ ] **Step 1:** testflight Fastfile 헤더에 부록 C 주석 블록 존재 확인·추가
- [ ] **Step 2:** Gemfile에 부록 D 주석 존재 확인·추가
- [ ] **Step 3: 검증** Run `ruby -c .github/util/flutter/testflight-wizard/templates/Fastfile 2>/dev/null || echo "ruby 미설치 — do/end 균형 육안 확인"` → Expected: Syntax OK 또는 육안확인

---

### Task 5: 검증 + 커밋 + 푸시

- [ ] **Step 1:** Run `git status --short | grep -vE "^\?\?"` → Expected: 마법사 관련 변경 파일들
- [ ] **Step 2:** Run `cd .github/util/flutter && grep -rl "flutter-ios-testflight-init" . ; grep -c "function generateSetupCommand" playstore-wizard/playstore-wizard.js` → Expected: 첫째 없음, 둘째 0
- [ ] **Step 3: 사용자 승인 후 커밋** (⚠️ AI 흔적 금지, 사용자 승인 필수). 메시지:
```
AppStore/PlayStore 배포 지원 대폭 개선 : feat : 마법사 완료단계에 배포 모드·출시 로드맵 안내 추가, 템플릿 옵션별 가이드 주석 보강, testflight 옛 경로·Appfile 오안내·playstore 죽은 함수 정리 https://github.com/TEAM-ROMROM/RomRom-FE/issues/934
```
- [ ] **Step 4:** 사용자 요청 시 `git push origin main`

---

## 부록 — 삽입할 실제 코드

### 부록 A: testflight 완료단계 안내카드 (iOS)
- bg-indigo-900/30 카드. 제목 "🚀 배포 모드 & 출시 로드맵".
- DEPLOY_MODE/IOS_DEPLOY_MODE 설명, store_only(기본·안전)/store_prepare(Add for Review)/store_submit(완전자동) 3줄.
- 출시 로드맵 3단계: ①store_only로 TestFlight 검증 ②최초 1회 ASC 직접 심사제출(신규앱 필수) ③출시 후 prepare/submit 전환.
- 모드 변경 위치: 저장소 Settings→Secrets and variables→Actions→Variables→IOS_DEPLOY_MODE. 상세는 ios/fastlane/Fastfile.

### 부록 B: playstore 완료단계 안내카드 (Android)
- 부록 A와 동일 구조, Android 용어로: internal 트랙 업로드/ANDROID_DEPLOY_MODE.
- store_prepare=production draft→Play Console "출시 시작", store_submit=production completed 심사 자동등록.
- 로드맵: ①store_only internal 검증 ②최초 1회 Play Console 수동 프로덕션 출시(Draft App 자동승급 불가) ③전환.
- 상세는 android/fastlane/Fastfile.playstore.

### 부록 C: testflight Fastfile 헤더 주석
```
# 【배포 모드 DEPLOY_MODE】 store_only(TF까지·기본) / store_prepare(제출직전·ASC에서 Add for Review) / store_submit(심사 자동제출)
# 【신규 앱】 App Store 최초 1회는 ASC에서 직접 심사제출/출시 필요. 이후 prepare/submit 정상동작.
# 【로케일】 What's New 메타는 'ko'만 유효(ko-KR 무효). 추가는 DELIVER_LOCALES ENV.
# 【개인정보】 연락처·데모계정은 app_review_information 미전달로 ASC 기존값 보존(하드코딩 금지).
```

### 부록 D: Gemfile 주석
```
# Fastlane — iOS 빌드/배포 자동화. Ruby 3.4+ 호환 위해 2.228 이상.
gem "fastlane", "~> 2.228"
# multi_json — google-apis transitive 의존성 gemspec 선언 누락 upstream 버그 회피(Gem::LoadError 방지). 유지 권장.
gem "multi_json"
```

## Self-Review
- Spec coverage: 버그검증(T1,2)+완료단계안내(T3)+템플릿주석(T4)+커밋(T5) → 사용자 요구 전부 커버.
- 입력 vs 안내 원칙: 배포모드는 ENV/variable 제어값(셋업 스크립트가 파일에 안 박음) → 완료단계 안내로 처리(원칙 부합).
- Placeholder 없음(실제 HTML/Ruby/명령 포함). 타입/이름 운영코드와 일치(IOS_DEPLOY_MODE, keystoreCreationCommandText, DELIVER_LOCALES).
