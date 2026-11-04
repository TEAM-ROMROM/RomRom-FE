# 교환 요청 개선 설계 (FE #1005 / BE #859)

추가금 금액·한 줄 메시지, 거절 보존과 보낸 쪽 상태(대기·확인함·거절됨), 물품 예약중 표시.
스토어 앱 v1.10.142가 새 서버에서도 그대로 동작해야 하므로 서버 변경은 추가 위주로 한다.

## API 계약 (BE)

| API | 변경 |
|---|---|
| `POST /api/trade/post` | 선택 파라미터 `extraChargeAmount`(정수, 원), `requestMessage`(문자열) |
| `POST /api/trade/update` | 같은 두 값 선택. 미전송 > 기존 값 유지, `EXTRA_CHARGE` 해제 > 추가금 삭제 |
| `POST /api/trade/reject` | 행 삭제 대신 `tradeStatus=REJECTED` + `rejectedAt` |
| `POST /api/trade/get/received` | REJECTED 제외 (기존 화면과 같은 목록) |
| `POST /api/trade/get/sent` | 선택 파라미터 `includeRejected`(기본 false). true일 때만 REJECTED 포함 |
| `POST /api/trade/get` | 받은 사람이 처음 열면 `checkedAt` 기록 (기존 `isNew=false`와 함께) |
| 물품 응답 전체 | Item에 `reservedAt`, `isReserved`(읽기 전용) 추가 |

TradeRequestHistory 응답 추가 필드: `extraChargeAmount`, `requestMessage`, `checkedAt`, `rejectedAt` (없으면 null).
에러 코드 추가: `INVALID_TRADE_EXTRA_CHARGE_AMOUNT`, `INVALID_TRADE_REQUEST_MESSAGE` (400). 비속어는 기존 `PROHIBITED_CONTENT`.

마이그레이션 `V1_4_70`: trade_request_history 컬럼 4개, trade_status 체크 제약 0~5, item.reserved_at + 부분 인덱스.

## 결정

- 결정: 추가금 범위 0~10,000,000원. `EXTRA_CHARGE` 옵션을 고르지 않으면 금액은 무시하고 null 저장 (400 아님).
- 결정: 앱은 0원을 미입력으로 처리 (콤마 포맷터가 빈 칸을 0으로 채우기 때문).
- 결정: 메시지는 앞뒤 공백 제거 후 최대 100자(코드포인트), 줄바꿈·탭·제어문자·줄 구분자 거부, UGC 비속어 필터 적용. 공백만 > null.
- 결정: REJECTED는 TradeStatus 끝(ordinal 5)에 추가. 구버전 앱은 `includeRejected`를 보내지 않아 REJECTED를 받지 않는다. 상세 조회(`/get`)에서 거절 건이 오면 구버전 앱은 문자열로 받고 `fromServerName`이 null을 돌려주므로 크래시 없음.
- 결정: 거절 후 같은 물품 쌍 재요청은 지금처럼 허용 (중복 검사·유니크 인덱스가 REJECTED를 보지 않음).
- 결정: '확인함' = PENDING + (`checkedAt` 있음 또는 `isNew=false`). 기존 행도 `isNew`로 판정 가능.
- 결정: 예약중은 새 ItemStatus 값이 아니라 별도 필드. 구버전 앱은 내 물품 목록을 AVAILABLE·EXCHANGED로 나눠 조회하고 서버 쿼리도 AVAILABLE 기준이라 새 상태값을 넣으면 물품이 사라진다.
- 결정: 예약 시작 = 받은 사람이 채팅방을 만드는 순간(PENDING > CHATTING), 두 물품(받은·보낸) 모두. 예약중은 표시만 하고 요청을 막지 않는다.
- 결정: 예약 해제 = 진행 중 거래(CHATTING·TRADE_COMPLETE_REQUESTED, 두 물품 모두 교환 가능·미삭제)가 남지 않은 물품. 교환 완료 3경로(요청 수락·채팅 완료 확정·관리자 강제 완료)는 즉시, 나머지(채팅방 나가기·관리자 취소/종료·물품 삭제·강제탈퇴)는 1분 주기 스케줄러가 정리.
  ChatRoomService(667줄)는 다른 작업과 충돌을 피하려고 건드리지 않았다.
- 결정: 교환 완료 시 두 물품이 포함된 남은 PENDING 요청은 CANCELED (구버전 앱도 이미 아는 값, 목록에서 빠짐). 채팅 중인 다른 방은 기존 시스템 메시지 그대로.
- 결정: 대기 요청이 정리될 때 알림은 보내지 않음. 맞는 기존 알림 타입이 없고 새 타입은 D 묶음 담당.
- 결정: 물품 상태를 손으로 교환완료로 바꾸는 경우는 다시 교환 가능으로 되돌릴 수 있어 대기 요청을 정리하지 않음.

## 설정 스위치

없음. 구버전 앱을 막거나 기존 응답의 의미를 바꾸는 동작이 없다 (모두 추가 필드·선택 파라미터·제외 기본값).

## 앱 (FE)

- 요청하기: 추가금 방식 선택 시 금액 칸, 한 줄 메시지 칸(100자, 줄바꿈 차단). 키보드가 올라오면 화면을 줄이고 스크롤.
- 받은·보낸 요청 카드: `추가금 N원`, `"메시지"` 한 줄.
- 보낸 요청: `includeRejected=true`로 조회, 대기·확인함·거절됨 태그. 거절 건은 수정·취소 메뉴를 숨긴다.
- 예약중 태그: 물품 상세, 등록 탭 목록, 마이페이지 등록 물품, 프로필 교환 물품. 홈 피드 카드는 다른 모델(HomeFeedItem)이라 이번 범위에서 제외.
