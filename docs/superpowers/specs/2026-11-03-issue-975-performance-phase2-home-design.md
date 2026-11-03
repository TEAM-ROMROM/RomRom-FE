# #975 성능 개선 2단계 G1 설계 (홈·탭)

- 이슈: https://github.com/TEAM-ROMROM/RomRom-FE/issues/975
- 1단계: `2026-11-03-issue-975-performance-phase1-design.md`
- 원칙: 화면 동작은 그대로, 성능만 바꾼다. 요청관리·알림 화면·채팅방·세션 정리 파일은 다른 작업 소유라 수정하지 않는다

## 항목별 원인과 설계

| # | 항목 | 원인 (코드 확인) | 설계 |
|---|---|---|---|
| 1 | 다음 카드 이미지 미리 받기 | 세로 `PageView`는 보이는 카드만 만듦 > 넘긴 직후 이미지 다운로드 시작 | 카드 표시 크기 계산을 `HomeFeedItemWidget.imageDisplaySize` 하나로 모으고, 같은 크기로 `CachedImage`와 같은 캐시 키(`AppImageCacheManager` + `ImageDecodeSize.forDisplay` > `ResizeImage`)를 만드는 `precacheCachedImage` 유틸 추가. 현재 카드 뒤 2장의 첫 이미지를 미리 받음 (URL 중복 요청 제외, 피드 교체 시 초기화) |
| 2 | 넘길 때 재빌드·디스크 쓰기 | 넘길 때마다 (1) 화면 `setState` (2) `markSeen`이 `HomeFeedState`를 새로 내보내 `ref.watch` 재빌드, 매번 전체 기록 `SharedPreferences` 저장 | 본 물품 기록을 화면 상태(`HomeFeedState`)에서 빼서 notifier 소유 `HomeFeedSeenItemHistory`(최근 100개 LRU)로 분리 > 넘겨도 피드 상태 변화 없음. 저장은 첫 기록 후 2초 묶음 1회. 앱 비활성·백그라운드, 홈 탭 이탈, 세션 초기화(provider dispose) 때 즉시 저장. `onPageChanged`는 광고 칸 여부가 바뀌거나 AI 하이라이트를 지울 때만 `setState` |
| 3 | 탭 다녀오면 첫 카드로 | `main_screen`이 홈 탭 재진입마다 `refresh(tabReentry)` > 30초 지났으면 page 0 교체 + `jumpToPage(0)` | 탭 재진입 새로고침 제거 (`RefreshTrigger.tabReentry` 삭제). 앱 복귀(`foregroundResume`)·빈 피드 새로고침·탐색 범위 변경 새로고침은 유지 |
| 4 | 탭 지연 생성 | `initState`에서 탭 5개 위젯을 만들어 `IndexedStack`에 모두 올림 > 요청관리(거래 요청)·마이페이지(프로필) 조회가 첫 화면과 동시 실행 | `LazyIndexedStack`: 처음 선택된 탭만 만들고 이후 유지. 홈(0)·채팅(3)은 시작 시 생성 (채팅 탭이 웹소켓 방 구독으로 하단 탭 안 읽음 점을 실시간 갱신, 첫 로드 전환(`AsyncLoading > AsyncData`)을 봐야 구독하므로 지연 시 구독 누락). 요청관리·등록·마이페이지는 첫 방문 시 생성 (`listenManual(fireImmediately: true)`·`ref.watch`라 늦게 만들어도 신호·데이터 반영). 푸시 갱신은 받은 요청 provider가 아직 없으면 건너뜀 (첫 방문 때 새로 조회) |
| 5 | 카드마다 상세 API (N+1) | 카드 `initState`가 `getItemDetail` 호출 > AI 가격 여부·좋아요 상태 갱신 | AI 가격 여부는 목록 응답 `isAiPredictedPrice`를 `HomeFeedItem.aiPrice`로 매핑, 카드의 상세 응답 AI 가격 덮어쓰기 제거. **좋아요 여부(`isLiked`)는 목록 응답에 없음**(#973 서버 항목) > 좋아요 상태 동기화용 상세 호출은 유지 |
| 6 | 상세 화면 스켈레톤 | 상세 응답 전 `isLoading = true` > 스켈레톤 | `HomeFeedItem`에 목록 응답 원본(`sourceItem`)을 보관, 상세 화면은 같은 물품이면 원본으로 먼저 그리고(주소 변환도 바로 시작) 상세 응답이 오면 교체. 실패 처리(탈퇴 회원·삭제 물품·오류 화면)는 그대로 |
| 7 | 광고 도착 후 요청 | 광고 칸 위젯이 만들어질 때 `NativeAd.load()` | `HomeFeedNativeAdPreloader`: 다음 광고 칸이 2페이지 이내면 광고 1개 미리 로드 > 광고 칸이 생기면 가져가 표시(소유권 이전, 로드 중이면 완료 대기). 50분 지난 미사용 광고는 폐기, 실패하면 버리고 다음 기회에 재요청. 광고 ID 없으면 아무것도 안 함 |
| 8 | 배지 때문에 알림 20건 | 홈 배지가 `notificationListProvider`(목록 20건 + 미확인 수)를 구독 | `notificationUnreadCountProvider`(미확인 수 API `getUnreadNotificationCount`) 추가, 홈 배지는 이것만 구독. 알림 목록 provider는 미확인 수를 이 provider로 조회해 같은 값 공유 (전체 읽음 후 재조회 > 배지 0). 푸시 갱신은 알림 목록 provider가 아직 없으면 미확인 수만 조회 |
| 9 | 차단 미반영 | 피드 provider가 차단 상태를 모름 | 피드 provider가 `memberBlockProvider`를 `listen` > 차단 회원 물품을 현재 목록에서 제외, 이후 loadMore·refresh 결과에서도 제외. 화면은 목록 축소 시 보던 물품(없으면 다음 물품)을 유지하도록 위치 보정 |

## 의도한 동작 변화

- 다른 탭에 다녀와도 보던 카드 유지 (기존: 30초 지났으면 새 목록 첫 카드)
- 요청관리·등록·마이페이지 탭은 처음 누를 때 조회 시작 (처음 방문 시 로딩 표시가 잠깐 보일 수 있음)
- 상세 화면이 스켈레톤 없이 바로 열림 (판매자 지역은 기존처럼 조회 후 표시)
- 차단 직후 홈 피드에서 그 회원 물품이 바로 사라짐

## 하지 않는 것

- 좋아요 상태용 카드 상세 호출 제거 (서버 #973 필요)
- 요청관리 차단 반영, 알림 화면·목록 위젯 수정 (다른 작업 소유)
- 피드 `select` 레코드 구독: 본 물품 기록 분리 뒤 넘길 때 피드 상태가 바뀌지 않아 남은 상태 변화는 모두 화면 갱신이 필요한 변화 (이득 없음)
