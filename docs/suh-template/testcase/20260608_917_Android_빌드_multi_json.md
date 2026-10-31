## 테스트케이스: Android 테스트 APK 빌드 Fastlane multi_json 의존성 보강

| 구분 | 내용 |
|------|------|
| 이슈 번호 | #917 |
| 대상 | CI 워크플로 (`.github/workflows/ROMROM-ANDROID-TEST-APK.yaml`) |
| 담당자 | @Cassiiopeia |
| 작성일 | 2026-06-08 |
| 비고 | main 직접 hotfix (커밋 `4c1e1c9`) |

---

### TC-01: Android 테스트 APK 빌드 성공

| 항목 | 내용 |
|------|------|
| 전제조건 | main에 multi_json 의존성 추가 hotfix 반영 |
| 절차 | 이슈에 `@suh-lab app build` 댓글로 Android 테스트 APK 빌드 트리거 |
| 기대 | `Install Fastlane` step 정상 통과 → APK 빌드 완료, `Gem::LoadError` 미발생 |
| 결과 | |

### TC-02: Fastlane 정상 로드

| 항목 | 내용 |
|------|------|
| 절차 | 빌드 로그의 `Install Fastlane` step에서 `bundle exec fastlane --version` 출력 확인 |
| 기대 | `multi_json is not part of the bundle` 에러 없이 Fastlane 버전이 정상 출력 |
| 결과 | |

### TC-03: Gemfile 의존성 선언 확인

| 항목 | 내용 |
|------|------|
| 절차 | 워크플로 Gemfile 생성부 확인 |
| 기대 | `gem "fastlane"`, `gem "multi_json"` 두 항목이 선언됨 |
| 결과 | |

### TC-04: 앱 동작·다른 step 무영향

| 항목 | 내용 |
|------|------|
| 절차 | 전체 빌드 파이프라인(준비/APK 빌드/아티팩트/Firebase 배포) 진행 |
| 기대 | multi_json 추가가 다른 step에 영향 없음. APK 정상 산출 및 Firebase App Distribution 배포 성공 |
| 결과 | |
