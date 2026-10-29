# 전역 코드·UX·성능 개선 설계 (#940)

> 근거: `docs/architecture/audits/2026-10-29_전역_코드_UX_성능_감사.md` (main @ 5106cdd, v1.10.108)
> 이슈: https://github.com/TEAM-ROMROM/RomRom-FE/issues/940 — #937·#938 범위 흡수
> 사용자 지시: "다 처리해줘, 너가 계속 다 처리해줘" (질문 생략·전권 위임). 커밋은 매번 사용자 허락 후.

## 의도
감사에서 확인된 보안·사용자 버그·UX·성능·구조 문제를 전부 해소하고, 같은 문제가 다시 쌓이지 않게 규칙 테스트로 막는다.

## 목표 / 비목표 / 반목표
- 목표: 이슈 #940 작업 내용 6단계 전부. 단계마다 `dart format` + `flutter analyze` 0건 + `flutter test` 통과.
- 비목표: 새 기능, 디자인 리뉴얼, 서버 API 변경, 새 상태관리 라이브러리·코드 생성 도입(OpenAPI 등), 백엔드 enum 동기화 자동화.
- 반목표(이러면 실패): 구조 리팩터링이 동작을 바꿈 / 동결 목록(`docs/architecture/rules/*.allow`)에 줄 추가 / 기존 테스트 깨짐 / iPad에서 새 overflow.

## 제약
- CLAUDE.md 절대 규칙(CustomTextStyles, AppColors, navigateTo, CommonModal, enum 분리, Riverpod 4-레이어, isTablet, iPad 사이징) 준수.
- 새 라이브러리 추가 금지(내 판단): 캐시는 메모리 Map, 동시성 잠금은 `Completer`로 구현.
- 단계 = 커밋 묶음. 각 단계는 독립적으로 리뷰·롤백 가능하게.

## 단계와 결정 사항
### 1단계 보안·인증
- 로그 인터셉터: `Authorization`·`Cookie` 헤더, `accessToken`·`refreshToken`·`password` 필드 마스킹. 출력은 `kDebugMode || TEST_BUILD`일 때만, 본문은 길이 제한(내 판단: 2,000자).
- 토큰 재발급: `ApiClient`의 구현 하나로 통일, 진행 중 재발급이 있으면 같은 Future를 기다림. `RomAuthApi.refreshAccessToken`은 그 단일 구현에 위임.
- `ApiException(statusCode, errorCode, message)` 도입. `ApiClient`가 non-2xx에서 이 예외를 던지고 `ErrorUtils`는 타입으로 판별(문자열 정규식 제거, 하위호환 위해 기존 문자열 경로는 폴백 유지). 409 → 이메일 중복 분기 복구.

### 2단계 사용자 버그·UX
- 물건 수정 = `myItemsProvider.notifier.update(request)` (API + 재조회). 이미지 업로드는 repository 경유.
- 차단은 `memberBlockProvider.setBlocked`, 알림설정은 `notificationSettingProvider` 경유.
- 빈 이미지는 `CachedImage`의 기존 `ErrorImagePlaceholder` 처리에 맡김(picsum 제거). 상대 경로 이미지는 `AppUrls.imageBaseUrl`(https).
- `public/index.html` iOS 링크 = `https://apps.apple.com/app/id6748823976` (`app_review_service.dart`의 기존 id).
- 웹소켓 주소 = `AppUrls.baseUrl`에서 `wss://…/chat` 파생.
- 빈/에러 상태: 기존 `EmptyStateView` 재사용, 에러일 때 "다시 시도" 버튼. 채팅 목록·등록 탭·좋아요·홈.
- `CommonModal` 확인 버튼: 비동기 `onConfirm`이면 완료까지 버튼 잠금 + 로딩 표시. 폭은 고정 312px.
- 채팅하기: in-flight 가드 + 로딩.
- 등록/수정 화면: 변경이 있으면 `PopScope`로 이탈 확인 모달.
- 로그아웃·거래 "확인 및 완료하기"에 확인 모달. 진행 중 버튼 비활성 표시.
- 채팅방 신고 결과 안내, 채팅방 차단 성공 안내. 신고 화면 키보드 인셋 처리. 알림 무한 스크롤 페이징.
- 글자 크기: `TextScaler`를 시스템 값으로 하되 상한 1.2배(내 판단: 고정 높이 레이아웃 overflow 위험 때문에 보수적으로). 아이콘 전용 버튼에 `Semantics` 라벨/tooltip, 30px 터치 영역 → 44px.
- 문구(내 판단): 앱 내 표기 "물품"으로 통일(현재 60:38로 다수), "판매중/판매 중" → "교환 가능", "…실패: " 접두 제거하고 `ErrorUtils` 메시지만, `'Unknown'`·"물품 ID가 없습니다" 같은 개발자 문구는 사용자 문구로.

### 3단계 성능
- `LocationService` 주소 변환: 좌표 반올림(소수 4자리) 키 메모리 캐시 + 진행 중 요청 공유 + 공유 `http.Client`. 피드·내 물건·좋아요는 `Future.wait`.
- `CachedImage`: 표시 폭 × devicePixelRatio로 `memCacheWidth`(폭을 모를 때는 미지정).
- 알림 권한 요청은 첫 프레임 이후(스플래시 진입 후). 시작 초기화는 서로 무관한 것만 `Future.wait`.
- 카드 덱: 아이콘 애니메이션은 카드 당길 때만 재생. 드래그 갱신은 `AnimatedBuilder` 국소 갱신으로 setState 축소(동작·감촉 불변).
- 홈 더보기 `_inFlight` 가드 + 끝에서 화면 1.5개 전 선행 로드. 요청관리 탭 첫 listen 중복 로드 제거. 등록 탭 스크롤 setState는 값이 바뀔 때만.
- 30초 폴러는 백그라운드에서 중지.

### 4단계 상태관리 확대
- 알림: `NotificationRepository` → `NotificationListState` → `notificationListProvider`(AsyncNotifier, 페이징·삭제·전체읽음 후 재조회). 홈 배지도 구독.
- 회원정보 6곳 → `memberProfileProvider` 구독/`ref.read(...future)`.
- 채팅방 나가기/삭제 후 `chatRoomsProvider` 재조회. 요청관리 수신 목록은 `tradeRequestsProvider`가 fetch까지 소유.
- 모델의 지오코딩 호출은 provider(또는 repository)로 이동. `api_client`·`auth_service`의 화면 이동은 상위(앱 루트 listener)로 이동.

### 5단계 대형 파일 분해
- #937 진행분 이어서 마무리 + provider 상태 직접 변경 제거. 상세·채팅방·카드 덱·등록 폼 각 500줄 이하, 추출 위젯은 `lib/widgets/<화면명>/`. 순수 UI 추출, 동작 불변.

### 6단계 정리·단일 원본·문서
- 미사용 5파일·`lib/deprecated/`·죽은 `_handleResponse` 삭제. 태그 위젯 4개 → 공통 태그 1개(색·크기 파라미터). 디버그 패널 공통 베이스. 신고 화면 2개 → 대상 타입 파라미터 1개.
- enum `fromServerName`은 전부 nullable 반환 + 호출부 폴백(크래시 금지).
- Dart 쪽 주소는 `AppUrls` 단일 원본, `functions`/`public`은 `app-config.js` 한 쌍에 맞춤(JS는 별도 런타임이라 파일 2개 유지, 값 일치 확인). Android: 실제 사용 중인 groovy `build.gradle` 유지, 무효한 `.kts` 삭제, CI 체크 경로 수정 — 단 삭제 전 Gradle이 어느 쪽을 쓰는지 빌드로 확인.
- 문서: `prompts/` 참조 제거(또는 `code-style.md`로 대체), `state-management.md` provider 현황표 갱신, 스킬 이름 `/cassiiopeia:*` → 설치된 `projectops:pro-*`, `git-rules.md` git add 모순 해소, 중복 섹션은 링크로.

## 빌더에게 맡긴 것
- 파일별 정확한 분해 경계, 위젯 이름(코딩 규칙 2장 준수), 테스트 케이스 구성.
- 각 단계 완료 시 `ledger tighten`으로 동결 목록 축소.

## 확인 필요(실기기)
- iPad·글자 크기 1.2배에서 overflow, 신고 화면 키보드, 카드 덱 감촉 — 단계 완료 후 시뮬레이터 스모크.
