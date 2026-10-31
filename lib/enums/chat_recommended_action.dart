/// 채팅방 AI 추천 행동 (BE ChatRecommendedAction, #759)
/// 추천 문구·버튼 문구 > 채팅 입력창 위 추천 배너에 표시
enum ChatRecommendedAction {
  none(serverName: 'NONE', recommendationMessage: '', actionLabel: ''),
  sendLocation(serverName: 'SEND_LOCATION', recommendationMessage: '만날 위치를 공유해보세요', actionLabel: '위치 보내기'),
  requestTradeCompletion(
    serverName: 'REQUEST_TRADE_COMPLETION',
    recommendationMessage: '교환을 마쳤다면 완료를 요청해보세요',
    actionLabel: '교환 완료 요청',
  ),
  cancelTradeCompletionRequest(
    serverName: 'CANCEL_TRADE_COMPLETION_REQUEST',
    recommendationMessage: '보낸 교환 완료 요청을 취소할 수 있어요',
    actionLabel: '요청 취소',
  ),
  rejectTradeCompletionRequest(
    serverName: 'REJECT_TRADE_COMPLETION_REQUEST',
    recommendationMessage: '아직 교환 전이라면 요청을 거절할 수 있어요',
    actionLabel: '요청 거절',
  ),
  confirmTradeCompletion(
    serverName: 'CONFIRM_TRADE_COMPLETION',
    recommendationMessage: '교환을 마쳤다면 완료를 확정해보세요',
    actionLabel: '교환 완료',
  );

  final String serverName;
  final String recommendationMessage;
  final String actionLabel;

  const ChatRecommendedAction({
    required this.serverName,
    required this.recommendationMessage,
    required this.actionLabel,
  });

  /// 노출 대상 추천 여부 (NONE 제외)
  bool get isRecommendation => this != ChatRecommendedAction.none;

  /// 서버 이름 > 추천 행동 (모르는 값·null > none, 배너 미노출)
  static ChatRecommendedAction fromServerName(String? name) {
    return ChatRecommendedAction.values.where((action) => action.serverName == name).firstOrNull ??
        ChatRecommendedAction.none;
  }
}
