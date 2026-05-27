import 'package:romrom_fe/events/app_event.dart';

/// 거래가 완료(EXCHANGED)됐을 때 발행되는 이벤트.
///
/// 채팅방에서 거래완료를 확정했거나(확정자), 상대방의 거래완료를 WebSocket으로 수신한 경우
/// 발행된다. 내 물건 목록을 보여주는 화면(홈 카드 덱·요청관리·마이페이지)이 구독해 재조회한다.
class TradeCompletedEvent extends AppEvent {
  const TradeCompletedEvent();
}
