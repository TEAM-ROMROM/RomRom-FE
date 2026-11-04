# 강제 업데이트 흐름 보강 설계 (#983)

## 배경
- 최소 버전 빈 값·`v1.10.10` 형식 > `FormatException` > "업데이트 불필요" 처리 > 강제 업데이트 꺼짐
- 스플래시 전체 제한 15초 = HTTP 제한 15초 > 버전 API 지연 시 '다시 시도'만 반복
- 앱 복귀 시 강제 업데이트 화면 위로 딥링크 이동 > 우회 가능
- 복귀 확인이 API 실패에도 확인 시각 저장 > 24시간 재확인 없음, `AppVersionApi()` 직접 호출

## 결정
### 1. 버전 파싱·판정 (`lib/utils/app_version_comparison.dart`)
- 형식: 앞 `v`/`V`·공백 허용, 숫자 마디 1개 이상, `-beta`·`+12` 접미사 무시. 그 외 null
- 마디 수 차이: 짧은 쪽 0 채움 (`1.10` = `1.10.0`)
- 형식 오류 처리
  - 설치 버전 > 판정 생략(none)
  - 최소 버전 > 경고 로그 + 강제 판정만 생략, 최신 버전 판정 유지
  - 최신 버전 > 권장 판정만 생략
- 로그: `[app version] minimum version ignored : invalid "..."` (출력 불가 문자 > `?`, 20자 제한)
- 응답 모델: 필드 null > 빈 문자열 (형식 판정은 판정 함수 한 곳)

### 2. 버전 확인 제한 시간 (`AppVersionRepository`)
- `versionCheckTimeout` 5초, 초과 시 null(판정 불가) > 시작 흐름은 none으로 통과
- 스플래시 전체 제한 = 버전 확인 5초 + HTTP 기본 15초 = 20초 (상수 합으로 계산, 2차 안전망)
- 제한 시간은 repository 한 곳 > 스플래시·앱 복귀 공통

### 3. 강제 업데이트 잠금 (`lib/services/forced_update_lock.dart`)
- 강제 업데이트 화면 표시 여부 단일 원본. 한 번 잠그면 프로세스 종료까지 유지
- 진입점 하나: `AppUpdateScreen.showForcedUpdate` (잠금 > 스택 교체), 스플래시·복귀 공통
- 잠금 중 차단
  - `RomRomDeepLinkRouter.receive`: 링크 폐기 (업데이트 전엔 열 수 없어 보관 의미 없음)
  - `onMainScreenEntered` 다음 프레임 열기: 생략
  - 세션 종료 화면 이동(`_navigateFromRoot`): 생략 (업데이트 화면 위 로그인 화면 우회 방지)
  - 앱 복귀 버전 확인: 생략 (같은 화면 재교체 방지)
- Riverpod 대신 plain 싱글턴: 정적 라우터(`DeepLinkGate`와 같은 계층)에서 읽고, 화면이 구독할 상태가 아님

### 4. 앱 복귀 확인 (`lib/services/resume_version_check_service.dart`)
- `appVersionRepositoryProvider` 경유 (`fetchServerUpdateType` 주입 > 테스트 교체 가능)
- 서버 응답 받은 경우만 확인 시각 저장. 실패·시간 초과 > 다음 복귀 때 재확인
- 진행 중 중복 복귀 > `_isChecking` 가드
- 저장 키 `last_version_check_timestamp` 유지 (기존 기록 호환)

## 테스트
- 비교: `1.10.9 < 1.10.10`, 마디 수 차이, v 접두어·접미사, 64비트 초과
- 최소 버전 빈 값·형식 오류 > 최신 버전 판정 유지
- repository 5초 제한 초과 > null, 늦은 응답 무시 / 스플래시 순서 5초 후 다음 화면
- 복귀 확인 실패 > 시각 미저장, 진행 중 중복 차단
- 잠금 중 딥링크 수신·보관 링크 열기 차단

## 하지 않는 것
- 서버 최신 버전 갱신 시점(심사 중 권장 안내) > #973
- 개별 API별 HTTP 제한 시간 조정
