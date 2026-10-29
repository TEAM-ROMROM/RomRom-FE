# 1단계 보안·인증 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** HTTP 로그의 토큰 노출 제거, 토큰 재발급 단일화(동시 요청 잠금), 상태 코드를 담은 API 예외로 죽은 409 분기 복구.

**Architecture:** 순수 함수(`LogMasking`, `SingleFlight`)를 먼저 만들고 테스트한 뒤, `LoggingHttpClient`·`ApiClient`·`RomAuthApi`·`ErrorUtils`가 이를 사용하게 바꾼다. `ApiClient`의 두 send 메서드는 공통 인증·재시도 파이프라인 하나로 합친다. 공개 시그니처(`sendHttpRequest`, `sendMultipartRequest`, `RomAuthApi.refreshAccessToken`)는 유지해 호출부 수정 없음.

**Tech Stack:** Flutter, `package:http`, `flutter_test`. 새 의존성 없음.

**Spec:** `docs/superpowers/specs/2026-10-29-global-code-ux-performance-design.md` (1단계)

## Global Constraints
- 새 라이브러리 추가 금지. 공개 API 시그니처 유지.
- 주석: 한국어, 한 줄 요약·블록 머리글 (`~/.claude/coding-conventions.md` 7장). 로그 문구는 기존 스타일 유지.
- 코드 수정 후 `source ~/.zshrc && dart format --line-length=120 .` → `flutter analyze` 0 issue → `flutter test` 전체 통과.
- **커밋 금지** (프로젝트 CLAUDE.md: 사용자 허락 없이 git add/commit 금지). 각 Task의 마지막 단계는 "변경 파일 목록 보고".
- 로그 출력 조건: `kDebugMode || DebugConfig.isTestBuild`. 본문 최대 2,000자.
- 마스킹 대상 헤더: `authorization`, `cookie`, `set-cookie` (대소문자 무시). 마스킹 대상 필드: 키 소문자에 `token` 또는 `password` 포함 (중첩 Map/List 재귀). 치환 값: `***`.

## Review Focus
- 동시 401 3건 → reissue 1회만 호출, 3건 모두 재시도 성공 (Task 2 테스트)
- reissue 실패 후 다음 401에서 다시 reissue 시도 가능 (SingleFlight가 완료 후 비워짐) (Task 2 테스트)
- JSON이 아닌 응답 본문·빈 본문 로그 시 예외 없음 (Task 1 테스트)
- 기존 `ErrorUtils.getErrorMessage`가 일반 `Exception('...{"errorCode":"X"}')`에도 계속 동작 (Task 3 테스트)
- 소셜 로그인 409 → `EmailAlreadyRegisteredException`(registeredSocialPlatform 보존), `Exception('Error during sign-in')`으로 감싸지지 않음 (Task 4)

---

### Task 1: 로그 마스킹·출력 게이트

**Files:**
- Create: `lib/utils/log_masking.dart`
- Modify: `lib/utils/log_http_client_interceptor.dart`
- Modify: `lib/services/apis/rom_auth_api.dart:110` (토큰 앞 15자 출력 제거)
- Test: `test/utils/log_masking_test.dart`

**Interfaces:**
- Produces: `class LogMasking` 정적 메서드
  - `static const int maxBodyLength = 2000;`
  - `static Map<String, String> maskHeaders(Map<String, String> headers)`
  - `static dynamic maskJsonValue(dynamic value)` — Map/List 재귀, 민감 키 값 `***`
  - `static String formatBody(String rawBody)` — JSON이면 마스킹 후 pretty, 아니면 원문; `maxBodyLength` 초과 시 잘라내고 `… (N자 생략)` 부가
  - `static bool get isHttpLoggingEnabled` — `kDebugMode || DebugConfig.isTestBuild`

- [ ] **Step 1: 실패 테스트 작성** `test/utils/log_masking_test.dart`
  - `maskHeaders({'Authorization': 'Bearer abc', 'Content-Type': 'application/json'})` → `{'Authorization': '***', 'Content-Type': 'application/json'}`; 소문자 `cookie`도 `***`
  - `maskJsonValue({'refreshToken': 'r', 'nested': {'accessToken': 'a', 'name': 'n'}, 'list': [{'password': 'p'}]})` → 토큰·password 값만 `***`, `name` 유지
  - `formatBody('{"accessToken":"a","b":1}')`에 `"a"` 미포함, `"***"` 포함
  - `formatBody('not json')` == `'not json'`, `formatBody('')` == `''`
  - `formatBody('x' * 2500)` 길이 ≤ 2000 + 접미 문구, `'500자 생략'` 포함
- [ ] **Step 2: 실패 확인** — `flutter test test/utils/log_masking_test.dart` → 컴파일 실패
- [ ] **Step 3: `LogMasking` 구현**
- [ ] **Step 4: 인터셉터 적용** — `sendWithTimeout`에서 `isHttpLoggingEnabled`가 false면 모든 `debugPrint`·`_prettyJson`(jsonDecode 포함) 건너뜀(타임아웃·응답 재구성 로직은 그대로). true면 헤더는 `maskHeaders`, 폼 필드는 `maskJsonValue`, body·response는 `formatBody`. 기존 `_prettyJson`은 `LogMasking.formatBody`로 대체 후 삭제.
- [ ] **Step 5: `rom_auth_api.dart:110`** `'토큰 저장 성공: accessToken=...'` → `'토큰 저장 성공'`
- [ ] **Step 6: 통과 확인** — `flutter test test/utils/log_masking_test.dart` PASS, `flutter analyze` 0 issue
- [ ] **Step 7: 변경 파일 목록 보고** (커밋 금지)

### Task 2: 토큰 재발급 단일화 + 동시 요청 잠금

**Files:**
- Create: `lib/utils/single_flight.dart`
- Create: `lib/models/token_reissue_result.dart`
- Modify: `lib/services/api_client.dart`
- Modify: `lib/services/apis/rom_auth_api.dart` (`refreshAccessToken`)
- Test: `test/utils/single_flight_test.dart`

**Interfaces:**
- Produces:
  - `class SingleFlight<T> { Future<T> run(Future<T> Function() task); bool get isRunning; }` — 실행 중이면 같은 Future 반환, 완료(성공·실패 공통) 후 비움
  - `class TokenReissueResult { final Map<String, dynamic>? responseData; final bool isRefreshTokenExpired; bool get isSuccess => responseData != null; }`
  - `ApiClient.reissueTokens() -> Future<TokenReissueResult>` (public static) — 단일 reissue 구현: refreshToken 없으면 실패, `/api/auth/reissue` multipart POST(인증 없음), 403 SUSPENDED_MEMBER 처리(`_handleSuspendedResponse` 그대로), 200이면 토큰 저장(rotation: 새 refreshToken 없으면 기존 유지) 후 responseData 반환, 401 + `EXPIRED_REFRESH_TOKEN`이면 `isRefreshTokenExpired: true`. 화면 이동은 하지 않음. 내부적으로 `static final SingleFlight<TokenReissueResult> _reissueFlight`로 감쌈.
  - `ApiClient` 내부 `_refreshToken()` 삭제 → 401 재시도 경로는 `reissueTokens()` 호출, `isRefreshTokenExpired`면 기존 세션 만료 처리(토큰 삭제·하트비트 중단·회원 캐시 삭제·로그인 화면, `_isSessionExpiredHandling` 중복 방지) 수행
  - `RomAuthApi.refreshAccessToken() -> Future<bool>` (시그니처 유지) — `ApiClient.reissueTokens()` 위임. 성공 시 기존처럼 `UserInfo().saveLoginStatus(...)` + `fetchAndSaveMemberInfo()`; 만료면 `_tokenManager.deleteTokens()` 후 false. 로그인 화면 이동 없음(스플래시가 처리 — 기존 동작 유지).

- [ ] **Step 1: 실패 테스트** `test/utils/single_flight_test.dart`
  - 동시 3회 `run` → task 호출 1회, 세 결과 동일
  - 첫 task가 throw → 세 호출 모두 같은 에러, 이후 `run`은 task를 새로 호출 (호출 2회)
  - 완료 후 `isRunning == false`
- [ ] **Step 2: 실패 확인** — `flutter test test/utils/single_flight_test.dart` FAIL
- [ ] **Step 3: `SingleFlight`, `TokenReissueResult` 구현** → 테스트 PASS
- [ ] **Step 4: `ApiClient.reissueTokens` 구현, `_refreshToken` 제거, 401 경로 교체**
- [ ] **Step 5: `RomAuthApi.refreshAccessToken` 위임으로 교체** (호출부 `splash_screen.dart:222`, `chat_websocket_service.dart:163` 수정 없음 확인)
- [ ] **Step 6: 검증** — `flutter analyze` 0 issue, `flutter test` 전체 PASS
- [ ] **Step 7: 변경 파일 목록 보고**

### Task 3: ApiException + 공통 인증·재시도 파이프라인 + ErrorUtils

**Files:**
- Create: `lib/exceptions/api_exception.dart`
- Modify: `lib/services/api_client.dart` (두 send 메서드)
- Modify: `lib/utils/error_utils.dart`
- Test: `test/utils/error_utils_test.dart`, `test/exceptions/api_exception_test.dart`

**Interfaces:**
- Consumes: Task 2 `ApiClient.reissueTokens()`
- Produces:
  - `class ApiException implements Exception { final int statusCode; final String responseBody; final String? errorCode; final bool isAfterTokenRefresh; ApiException({required this.statusCode, required this.responseBody, this.isAfterTokenRefresh = false}); Map<String, dynamic>? get responseJson; }` — `errorCode`는 생성 시 body JSON `errorCode` 파싱(실패 시 null). `toString()`은 기존 문구 유지: `'API 요청 실패: $statusCode, $responseBody'` / `isAfterTokenRefresh`면 `'API 요청 실패 (토큰 갱신 후): …'` (기존 문자열 기반 호출부 호환).
  - `ApiClient._sendWithAuthRetry({required bool isAuthRequired, required Future<http.Response> Function(String? accessToken) execute}) -> Future<http.Response>` (private) — 토큰 확인 → 실행 → 제재(403)·UGC(400) 체크 → 2xx 반환 / 401이면 `reissueTokens()` 후 1회 재시도(**재시도 응답에도 제재·UGC 체크**) / 그 외 `ApiException` throw. 재발급 실패는 기존 문구 `Exception('토큰 갱신 실패: 재로그인 필요')` 유지.
  - `sendHttpRequest`·`sendMultipartRequest`는 이 파이프라인 사용. multipart의 `onSuccess` 호출 동작(2xx에서 jsonDecode 후 호출, 빈 body면 `{}`)은 유지, http 쪽은 기존처럼 미호출.
  - 죽은 `_handleResponse` 삭제(`log_utils` import가 더 안 쓰이면 함께 제거).
  - `ErrorUtils.getErrorMessage(Object error)`: `error is ApiException`이면 `ErrorCode.fromCode(error.errorCode).koMessage`; 아니면 기존 정규식 폴백(빈 catch에 이유 주석 한 줄).

- [ ] **Step 1: 실패 테스트**
  - `api_exception_test.dart`: body `{"errorCode":"DUPLICATE_REPORT","errorMessage":"x"}` → `errorCode == 'DUPLICATE_REPORT'`; body `'oops'` → `errorCode == null`; `toString()`이 `'API 요청 실패: 400, '`로 시작
  - `error_utils_test.dart`: `ApiException(400, '{"errorCode":"DUPLICATE_REPORT"}')` → `ErrorCode.fromCode('DUPLICATE_REPORT').koMessage`; `Exception('API 요청 실패: 400, {"errorCode":"DUPLICATE_REPORT"}')` → 같은 메시지(폴백); `Exception('plain')` → `ErrorCode.unknown.koMessage`
- [ ] **Step 2: 실패 확인**
- [ ] **Step 3: `ApiException` 구현 → api_exception 테스트 PASS**
- [ ] **Step 4: `ErrorUtils` 수정 → error_utils 테스트 PASS**
- [ ] **Step 5: `ApiClient` 파이프라인 통합** (두 메서드의 복제 흐름 제거)
- [ ] **Step 6: 검증** — `flutter analyze` 0, `flutter test` 전체 PASS
- [ ] **Step 7: 변경 파일 목록 보고**

### Task 4: 인증 API의 죽은 분기 복구

**Files:**
- Modify: `lib/services/apis/rom_auth_api.dart` (`signInWithSocial`, `getKakaoFirebaseToken`)

**Interfaces:**
- Consumes: Task 3 `ApiException` (`statusCode`, `errorCode`, `responseJson`)

- [ ] **Step 1: `signInWithSocial`** — `ApiClient`가 non-2xx를 던지므로 `else if (statusCode == 409)` 분기 제거. `on ApiException catch (e) when (e.statusCode == 409)` → `EmailAlreadyRegisteredException(registeredSocialPlatform: e.responseJson?['registeredSocialPlatform'] ?? '')`. `AccountSuspendedException`·`EmailAlreadyRegisteredException`는 기존처럼 rethrow, 그 외만 `Exception('Error during sign-in: …')`.
- [ ] **Step 2: `getKakaoFirebaseToken`** — non-2xx 분기를 `on ApiException catch (e)`로 이동: `statusCode == 409 || errorCode == 'EMAIL_ALREADY_REGISTERED'` (기존 키 `code`도 함께 확인: `e.responseJson?['code']`) → `EmailAlreadyRegisteredException`; `SUSPENDED_MEMBER` → `AccountSuspendedException`; 그 외 rethrow.
- [ ] **Step 3: 호출부 확인** — `lib/widgets/login_button.dart`의 두 예외 처리 경로가 그대로 맞는지 읽고 확인(수정 불필요 예상, 필요 시 보고).
- [ ] **Step 4: 검증** — `dart format`, `flutter analyze` 0, `flutter test` 전체 PASS, `flutter test test/architecture` PASS
- [ ] **Step 5: 변경 파일 목록 보고**
