/// AI 행동 추천 액션 enum (백엔드 ChatActionRecommendation)
enum ChatRecommendedAction {
  none,
  sendLocation,
  requestTradeCompletion,
  cancelTradeCompletionRequest,
  rejectTradeCompletionRequest,
  confirmTradeCompletion;

  static ChatRecommendedAction fromServerName(String? value) {
    switch (value) {
      case 'SEND_LOCATION':
        return ChatRecommendedAction.sendLocation;
      case 'REQUEST_TRADE_COMPLETION':
        return ChatRecommendedAction.requestTradeCompletion;
      case 'CANCEL_TRADE_COMPLETION_REQUEST':
        return ChatRecommendedAction.cancelTradeCompletionRequest;
      case 'REJECT_TRADE_COMPLETION_REQUEST':
        return ChatRecommendedAction.rejectTradeCompletionRequest;
      case 'CONFIRM_TRADE_COMPLETION':
        return ChatRecommendedAction.confirmTradeCompletion;
      default:
        return ChatRecommendedAction.none;
    }
  }
}
