# 3단계 성능 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 홈 피드 지연(주소 변환 순차·무캐시), 썸네일 원본 디코딩, 시작 시 권한 팝업 대기, 카드 덱 상시 애니메이션·전체 재빌드, 중복 로드를 줄인다. 사용자에게 보이는 동작·감촉은 바꾸지 않는다.

**Architecture:** 주소 변환은 `LocationService` 한 곳에 캐시를 두어 모든 호출부가 자동으로 혜택. 이미지 디코딩 크기는 `CachedImage` 한 곳에서. 나머지는 해당 파일 국소 수정.

**Tech Stack:** Flutter, Riverpod, cached_network_image, http. 새 의존성 없음.

**Spec:** `docs/superpowers/specs/2026-10-29-global-code-ux-performance-design.md` (3단계)

## Global Constraints
- 동작·감촉 불변(애니메이션 곡선·시간·제스처 결과 동일). 새 라이브러리 금지.
- CLAUDE.md 절대 규칙, 주석 한국어 한 줄(`~/.claude/coding-conventions.md` 2·7장), boolean `is/has/can/should`.
- 각 Task 끝: `source ~/.zshrc && dart format --line-length=120 lib test` → `flutter analyze` 0 → `flutter test` 전체 통과 → `ledger . check` 통과(`*.allow` 줄 추가 금지).
- 커밋 금지(컨트롤러가 단계 끝에 커밋). git add/commit/stash/checkout/restore/reset 금지.
- 주소 캐시 키: 위도·경도 소수 4자리 반올림 `'{lat},{lng}'`. 성공 결과만 캐시. 반환 `LocationAddress`의 위도·경도는 요청 좌표 그대로.
- `request_management_tab_screen.dart` 이중 로드는 5단계(대형 파일 분해)에서 처리 — 이번 단계에서 손대지 않음.

## Review Focus
- 같은 좌표 동시 요청 N건 → 네트워크 1회, 결과 N건 동일 (Task 1 테스트)
- 주소 변환 실패(null/예외)는 캐시하지 않아 다음 요청이 재시도 (Task 1 테스트)
- `Future.wait` 병렬화 후에도 피드 순서·id 부여 동일 (Task 1 테스트)
- `CachedImage`에 width가 없거나 무한대면 memCacheWidth 미지정 (Task 2 테스트)
- 카드 덱 드래그 중 아이콘 애니메이션은 기존처럼 보이고, 드래그 끝나면 멈춤 (Task 4)

---

### Task 1: 주소 변환 캐시·중복 요청 합치기·병렬화

**Files:**
- Create: `lib/services/address_lookup_cache.dart`
- Modify: `lib/services/location_service.dart:51-95`, `lib/models/home_feed_item.dart:54-90`, `lib/screens/my_page/my_like_list_screen.dart:~152-170`, `lib/screens/item_detail_description_screen.dart:148-156`
- Test: `test/services/address_lookup_cache_test.dart`, `test/models/home_feed_item_test.dart`(가능하면)

**Interfaces:**
- Produces: `class AddressLookupCache { AddressLookupCache({required Future<LocationAddress?> Function(double latitude, double longitude) fetchAddress}); Future<LocationAddress?> lookup(double latitude, double longitude); static String toCacheKey(double latitude, double longitude); void clear(); }` — 성공 결과 Map 캐시 + 진행 중 Future Map 공유(완료 후 제거), 반환 시 요청 좌표로 `LocationAddress` 재구성
- `LocationService.getAddressFromCoordinates` 시그니처 유지, 내부에서 캐시 경유. HTTP는 클래스 단일 `http.Client` 재사용(매 요청 새 연결 금지)

- [ ] Step 1: 실패 테스트 — 같은 좌표 2회 순차 → fetch 1회; 동시 3회 → fetch 1회·결과 동일; fetch가 null 반환 → 다음 lookup에서 다시 fetch; fetch throw → 예외는 lookup 밖으로 전파되지 않고 null(기존 `getAddressFromCoordinates`가 null 반환하던 동작과 동일), 캐시 안 됨; 소수 5자리만 다른 좌표 → 같은 키; 반환 위도·경도 = 요청 값
- [ ] Step 2~3: 구현 → PASS
- [ ] Step 4: `LocationService`에 연결, `HomeFeedItem.fromItems`·좋아요 목록은 `Future.wait`로 병렬(결과 순서·id는 입력 순서대로)
- [ ] Step 5: 상세 화면 — 이미 `homeFeedItem.location` 등 주소가 있으면 재조회 생략
- [ ] Step 6: 검증 + 보고

### Task 2: 썸네일 표시 크기 디코딩 + 위치 말풍선 캐시

**Files:**
- Modify: `lib/widgets/common/cached_image.dart`, `lib/widgets/chat_location_bubble.dart:41-83`
- Test: `test/widgets/common/cached_image_test.dart`

**Interfaces:**
- Produces: `CachedImage`에 선택 인자 `Map<String, String>? httpHeaders`; 내부 `memCacheWidth = (width * devicePixelRatio).round()` (width가 null·무한대·0 이하면 미지정), height만 있으면 `memCacheHeight` 동일 규칙

- [ ] Step 1: 실패 위젯 테스트 — width 100, DPR 3 → CachedNetworkImage.memCacheWidth == 300; width null → null; width infinity → null
- [ ] Step 2~3: 구현 → PASS
- [ ] Step 4: 위치 말풍선 정적 지도 `http.get` + `Image.memory` → `CachedImage(imageUrl:, httpHeaders:)`(같은 헤더), 주소는 Task 1 캐시 경유(이미 `LocationService` 사용이면 자동)
- [ ] Step 5: 검증 + 보고

### Task 3: 시작 시간 단축

**Files:**
- Modify: `lib/main.dart:43-80`, `lib/services/firebase_service.dart:33-45`, `lib/services/app_initializer.dart`, `lib/screens/splash_screen.dart:~114-125,~234`

- [ ] Step 1: 알림 권한 요청(`requestPermission`)을 `runApp` 이전 await에서 분리 — 리스너 등록은 그대로 시작 시, 권한 요청은 첫 프레임 이후(스플래시 진입 후) 1회. 기존 권한 결과 로그 동작 유지
- [ ] Step 2: `initialize()` 안에서 서로 의존 없는 초기화(`initNaverMap`, `initGoogleSignIn`)는 `Future.wait`. `.env` 로드·`DebugConfig.init`은 먼저(다른 초기화가 env를 읽음). Firebase 초기화 순서는 의존 관계를 확인해 안전할 때만 병렬화, 아니면 유지하고 보고
- [ ] Step 3: 스플래시 — 버전 체크를 기존 `Future.wait`에 합침(결과 처리 순서·강제 업데이트 분기 동일), `handleFcmToken`은 결과를 기다리지 않음(`unawaited`, 실패 로그 유지)
- [ ] Step 4: 검증(가능하면 시작 경로를 순수 함수로 분리해 테스트, 어려우면 보고에 근거 기재) + 보고

### Task 4: 카드 덱 애니메이션·재빌드 축소

**Files:**
- Modify: `lib/widgets/home_tab_card_hand.dart:125-145,~763,~834`

- [ ] Step 1: 아이콘 애니메이션 — `repeat` 상시 실행 제거, 카드를 당기기 시작할 때 `repeat(reverse: true)`, 놓을 때 `stop()`+초기 위치. 화면에 보이는 시점·모양 동일
- [ ] Step 2: 궤도 각도 — 컨트롤러 리스너의 화면 전체 `setState` 제거, 카드 변환 부분만 `AnimatedBuilder(animation: _orbitController)`로 갱신. `_handlePanUpdate`의 중복 `setState`(컨트롤러 값 설정과 동시 호출) 정리
- [ ] Step 3: 기존 카드 덱 테스트가 있으면 통과, 없으면 최소 위젯 테스트(펌프 후 아이콘 컨트롤러 비활성, 드래그 시작 시 활성)
- [ ] Step 4: 검증 + 보고(감촉 불변 근거: 곡선·시간·임계값 미변경 목록)

### Task 5: 중복 호출·불필요 재빌드 정리

**Files:**
- Modify: `lib/providers/home_feed_provider.dart:73-76`, `lib/screens/home_tab_screen.dart:~392`, `lib/screens/register_tab_screen.dart:~92-95`, `lib/services/chat_member_status_poller.dart:~45`, `lib/utils/log_http_client_interceptor.dart:~81`
- Test: `test/providers/home_feed_provider_test.dart`

- [ ] Step 1: 실패 테스트 — `loadMore` 동시 2회 → repository 호출 1회
- [ ] Step 2: `loadMore` in-flight 가드(`_isLoadMoreInFlight`), 홈 스크롤은 끝에서 뷰포트 1.5배 전에 선행 로드
- [ ] Step 3: 등록 탭 스크롤 리스너 — 값이 바뀔 때만 `setState`, 타이머 콜백 `mounted` 확인
- [ ] Step 4: 채팅 상대 상태 30초 폴러 — 앱 백그라운드에서 중지, 복귀 시 재개(하트비트와 같은 방식)
- [ ] Step 5: 로그 인터셉터 — 로깅 꺼짐이면 응답 `utf8.decode`·로그 문자열 조립 생략(응답 재구성 동작 동일)
- [ ] Step 6: 검증 + 보고
