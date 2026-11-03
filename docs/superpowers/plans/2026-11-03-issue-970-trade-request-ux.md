# 교환 요청·요청관리 사용성 개선 구현 계획 (#970)

설계: `docs/superpowers/specs/2026-11-03-issue-970-trade-request-ux-design.md`

## Task 1. 요청 표시값 getter (B3)
- [x] 테스트: `test/models/trade_request_history_display_test.dart` (requestedDate, requestedTradeOptions)
- [x] `trade_response.dart`에 `TradeRequestHistoryDisplayX` 확장 추가

## Task 2. provider 실패 상태·재시도·동시 호출 제한·수정·채팅방 찾기 (B1·B2·B4·B5)
- [x] 테스트(`test/providers/trade_requests_provider_test.dart`): 받은/보낸 실패 플래그, 재시도, 12개 카드 동시 호출 ≤ 5·순서 유지, updateTradeOptions, findChatRoomIdOfSentRequest
- [x] `TradeRequestsState`에 실패 플래그 2개
- [x] `TradeRepository.updateTradeOptions`
- [x] notifier: `retryReceivedLoad`·`retrySentLoad`·`updateTradeOptions`·`findChatRoomIdOfSentRequest`, `_loadSent` 묶음 호출

## Task 3. 내 물품 페이지 조회 (A1)
- [x] 테스트(`test/repositories/item_repository_my_items_page_test.dart`): hasMore 계산
- [x] `ItemRepository.getMyItemsPage` (`({items, hasMore})` 레코드 반환)

## Task 4. 보낸 요청 보기 신호 (A3)
- [x] `sentRequestsFocusTriggerProvider` + userScopedProviders 등록 + 문서 현황표

## Task 5. 교환 요청 화면 (A1·A2·A3)
- [x] enum `TradeRequestExistenceStatus`
- [x] 페이지 로드, 다른 물품 선택, 이미 요청/확인 실패 UI, 공용 인디케이터 사용
- [x] 위젯 테스트 갱신·추가 (`trade_request_screen_existence_check_test.dart`)

## Task 6. 요청관리 탭·목록 위젯 (B1~B7)
- [x] 10개 제한 제거, 인디케이터 숫자 표시
- [x] 목록 실패 뷰·재시도, 요청 시각·거래 방식·요청자 표시
- [x] 수정 시트, 채팅 중 이동, 교환 완료 삭제 확인
- [x] 위젯 테스트 갱신·추가 (`request_lists_test.dart`)

## Task 7. 검증
- [x] `dart format --line-length=120 .` > `flutter analyze` > `flutter test`
- [x] diff 자체 점검 (이슈 항목·규칙)
