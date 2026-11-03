# 교환 요청·요청관리 사용성 개선 설계 (#970)

- 이슈: https://github.com/TEAM-ROMROM/RomRom-FE/issues/970
- 범위: 클라이언트만. 서버 변경 필요 항목(추가금 금액·메시지, 거절/삭제 구분, 대기/확인함 상태, 페이지 크기 계약)은 제외
- 원칙: 공유 상태는 `tradeRequestsProvider` 단일 소유, mutation은 notifier 메서드 > 서버 재조회, 기존 public 메서드 이름 유지(#964 병합 충돌 최소화)

## A. 교환 요청 보내기 (`trade_request_screen.dart`)

### A1. 내 물품 21번째 이후 선택 불가
- 문제: `getMyItems(pageSize: 20)` 1페이지만 조회
- 변경: `ItemRepository.getMyItemsPage(status, pageNumber, pageSize)` 추가(다음 페이지 여부 포함) > 끝에서 3장 전 도달 시 다음 페이지 로드. 미리 고른 카드가 첫 페이지에 없으면 찾을 때까지 다음 페이지 로드
  - 탐색 상한 10페이지(첫 페이지 포함), 새 물품 0개 페이지면 중단, itemId 중복 제거
  - 탐색 중 조회 실패 > 안내 후 이미 받은 카드로 선택(찾은 위치, 없으면 첫 카드)·존재 확인 진행 (선택·확인은 성공·실패 공통 경로)
- 테스트: 저장소 `hasMore` 계산(서버 totalPages 기준, 없으면 개수 기준), 화면 슬라이드 시 다음 페이지 요청

### A2. 홈에서 고른 카드 고정
- 문제: `preSelectedCardId`로 들어오면 카드 1장만 표시, 변경 수단 없음
- 변경: 선택된 카드 아래 `다른 물품 선택` 버튼 > 카드 선택(PageView) 모드로 전환, 현재 카드 위치 유지
- 테스트: 버튼 탭 후 PageView 표시

### A3. 이미 요청한 물품 / 중복 확인 실패
- 문제: 안내 문구만 있고 이동 수단 없음, 확인 실패를 '요청 없음'으로 처리
- 변경: 확인 상태를 enum `TradeRequestExistenceStatus`(확인 중·요청 없음·이미 요청·확인 실패)로 관리
  - 이미 요청 > `보낸 요청 보기` 버튼: 요청관리 탭 이동 + 보낸 요청 토글 신호(`sentRequestsFocusTriggerProvider`)
  - 확인 실패 > 안내 + `다시 확인` 버튼, 요청하기 비활성
- 테스트: 확인 실패 시 선택 탭 대신 실패 안내·요청 버튼 비활성, 다시 확인 시 재조회

## B. 요청관리 탭

### B1. 판매중 물품 10개 제한
- 문제: `maximumItemCardCount = 10`
- 변경: 제한 제거. 보낸 요청 조회는 카드 수만큼 호출되므로 동시 호출 수 제한(5개씩 묶음). 인디케이터는 점 10개 초과 시 `현재/전체` 숫자 표시
- 테스트: 카드 12개 > 보낸 요청 12건 모두 조회·순서 유지·동시 호출 5 이하

### B2. 목록 조회 실패 = 없음
- 문제: 실패 시 빈 목록과 같은 '진행 중인 요청이 없습니다'
- 변경: 상태에 `hasReceivedLoadFailed`·`sentFailedItemIds`(보낸 요청 실패 카드 ID, `hasSentLoadFailed` getter) 추가
  - 받은 요청 실패 > `EmptyStateView.error` + 다시 시도(`reloadReceivedOfRequestedCard`)
  - 보낸 요청: 성공 카드 결과는 유지. 결과 있음 + 일부 실패 > 목록 상단 '일부를 불러오지 못했어요 · 다시 시도' 배너, 보여줄 결과 없이 실패 > 오류 뷰
  - `retrySentLoad`: 실패 카드만 재조회 후 카드 순서대로 다시 합침 (실패 카드 없으면 전체)
- 테스트: 실패 > 플래그 true, 재시도 성공 > false, 목록 위젯 실패 뷰

### B3. 요청 시각·거래 방식
- 문제: 'N분 전'이 물품 등록일, 태그가 물품 기본 거래 방식
- 변경: `TradeRequestHistory` 확장 getter `requestedDate`(요청 생성 시각), `requestedTradeOptions`(요청 시 고른 방식). 시각 없으면 시간 표시 생략
- 테스트: getter 단위 테스트, 목록 위젯이 요청 값을 카드에 전달

### B4. 보낸 요청 '수정'
- 문제: 내 물품 편집 화면을 엶
- 변경: `TradeRequestOptionEditSheet`(거래 방식 선택 시트, 기존 선택값 채움, 1개 이상·변경 시 저장) > `tradeRequestsProvider.updateTradeOptions` > 보낸 요청 백그라운드 재조회(저장 성공 즉시 반환). 서버가 대기(PENDING) 요청만 수정 허용 > 대기 상태에서만 메뉴 노출
  - 저장 중 닫힘 차단: 드래그 닫기 끔, 바깥 탭·뒤로가기는 `PopScope(canPop: !저장 중)`
  - 앱이 모르는 기존 서버 값은 선택값 뒤에 그대로 붙여 전송 (새 거래 방식 유실 방지)
- 테스트: notifier가 저장소에 1회 전달 후 보낸 요청 재조회, 실패 시 예외 전달

### B5. 보낸 요청 '채팅 중' 탭
- 문제: 물품 상세로만 이동
- 변경: 서버 채팅방 생성 API는 요청 받은 사람만 호출 가능 > 보낸 사람은 `getChatRoomsByItemId(내 물품)` 결과에서 `REQUESTED` + 상대 회원 일치 방을 찾아 채팅방 이동. 못 찾으면 안내 후 물품 상세
  - 상대 물품 대표 이미지가 있으면 방이 1개여도 이미지 일치 필수 (같은 상대의 다른 요청 방 열기 방지), 이미지 없으면 방이 1개일 때만
- 테스트: 매칭 규칙(유일 일치, 이미지로 구분, 불일치 > null)

### B6. 교환 완료 보낸 요청 탭 즉시 삭제
- 변경: 탭 시 확인 모달(`showDeleteDialog`) 후 삭제
- 테스트: 모달 확인은 기기 수동 확인

### B7. 받은 요청 요청자 정보
- 변경: 응답의 `giveItem.member`(닉네임·프로필)만 사용해 카드에 요청자 행 표시, 값 없으면 생략
- 테스트: 목록 위젯이 닉네임 전달

## 파일 크기 유지 (500줄 규칙)
- `trade_request_screen.dart`: 하단 버튼(`TradeRequestActionButtons`), 요청 존재 안내(`TradeRequestExistenceNotice`), 보조 버튼(`TradeRequestTextActionButton`) 위젯 분리
- `request_management_tab_screen.dart`: 거래 방식 수정 저장·안내를 시트 안으로 이동

## 규칙 예외: 교환 요청 화면의 저장소 직접 호출 (CLAUDE.md 규칙 1)
- `trade_request_screen.dart`는 `itemRepositoryProvider.getMyItemsPage`·`tradeRepositoryProvider.hasTradeRequest`를 직접 호출
- 근거: 두 조회 모두 이 화면에서만 쓰는 1회성 조회(다른 화면과 공유하는 상태 없음, 화면을 닫으면 버림) > `state-management.md`의 "1회성 조회·제출은 `ref.read(xxxRepositoryProvider)`" 허용 범위. 변경 전부터 같은 방식(`getMyItems`·`hasTradeRequest` 직접 호출)
- 화면 전용 notifier로 옮기려면 대상 물품별 family provider + 로그아웃 초기화 등록 + 화면 상태(페이지·확인 회차) 전체 이전이 필요해 이번 범위 밖. 요청 전송은 공유 상태라 `tradeRequestsProvider.sendRequest` 경유 유지

## 하지 않는 것
- 요청관리 탭 카드 원본 `myItemsProvider`의 판매중 물품 100개 상한 (`ItemRepository.getMyItems` 기본 pageSize 100, 1페이지만 조회): 이번 변경으로 탭 자체의 10개 제한은 없앴지만 101번째 이후 판매중 물품은 여전히 카드에 없음. 내 물품 전체 페이징은 여러 화면이 공유하는 provider 변경이라 별도 이슈
- 받은·보낸 요청 목록 자체 페이징(서버 페이지 크기 계약 필요)
- 거절/삭제 구분, 추가금·메시지, 대기/확인함 상태
