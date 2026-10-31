import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/chat_recommended_action.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/utils/chat_room_message_rules.dart';

const String myMemberId = 'me';
const String opponentMemberId = 'other';

/// 테스트용 메시지 (목록은 reverse: index 0 = 최신)
ChatMessage buildMessage(MessageType type, {String sender = myMemberId}) {
  return ChatMessage(chatRoomId: 'room-1', senderId: sender, type: type);
}

/// 기본 상태(입력 가능·미완료·대기 없음)에서 추천 행동 실행 가능 여부
bool canPerform(
  ChatRecommendedAction action, {
  String? activeTradeRequestSenderId,
  bool isInputDisabled = false,
  bool isTradeCompleted = false,
  bool isTradeActionPending = false,
}) {
  return canPerformRecommendedAction(
    action: action,
    isInputDisabled: isInputDisabled,
    isTradeCompleted: isTradeCompleted,
    isTradeActionPending: isTradeActionPending,
    activeTradeRequestSenderId: activeTradeRequestSenderId,
    myMemberId: myMemberId,
  );
}

void main() {
  group('findActiveTradeRequestSenderId', () {
    test('활성 요청 > 발신자, 요청 없음 > null', () {
      expect(
        findActiveTradeRequestSenderId(
          messages: [
            buildMessage(MessageType.text),
            buildMessage(MessageType.tradeCompleteRequest, sender: opponentMemberId),
          ],
          isTradeCompleted: false,
        ),
        opponentMemberId,
      );
      expect(
        findActiveTradeRequestSenderId(messages: [buildMessage(MessageType.text)], isTradeCompleted: false),
        isNull,
      );
    });

    test('요청 뒤 취소·거절 > null, 거래 완료 방 > null', () {
      expect(
        findActiveTradeRequestSenderId(
          messages: [
            buildMessage(MessageType.tradeCompleteRequestCanceled),
            buildMessage(MessageType.tradeCompleteRequest),
          ],
          isTradeCompleted: false,
        ),
        isNull,
      );
      expect(
        findActiveTradeRequestSenderId(
          messages: [buildMessage(MessageType.tradeCompleteRequest)],
          isTradeCompleted: true,
        ),
        isNull,
      );
    });
  });

  group('canPerformRecommendedAction', () {
    test('NONE > 항상 불가', () {
      expect(canPerform(ChatRecommendedAction.none), isFalse);
    });

    test('위치 보내기 > 입력 가능할 때만', () {
      expect(canPerform(ChatRecommendedAction.sendLocation), isTrue);
      expect(canPerform(ChatRecommendedAction.sendLocation, isInputDisabled: true), isFalse);
    });

    test('교환 완료 요청 > 활성 요청·완료·대기·입력 불가 아닐 때만', () {
      expect(canPerform(ChatRecommendedAction.requestTradeCompletion), isTrue);
      expect(
        canPerform(ChatRecommendedAction.requestTradeCompletion, activeTradeRequestSenderId: opponentMemberId),
        isFalse,
      );
      expect(canPerform(ChatRecommendedAction.requestTradeCompletion, isTradeCompleted: true), isFalse);
      expect(canPerform(ChatRecommendedAction.requestTradeCompletion, isTradeActionPending: true), isFalse);
      expect(canPerform(ChatRecommendedAction.requestTradeCompletion, isInputDisabled: true), isFalse);
    });

    test('요청 취소 > 내 활성 요청일 때만', () {
      expect(
        canPerform(ChatRecommendedAction.cancelTradeCompletionRequest, activeTradeRequestSenderId: myMemberId),
        isTrue,
      );
      expect(
        canPerform(ChatRecommendedAction.cancelTradeCompletionRequest, activeTradeRequestSenderId: opponentMemberId),
        isFalse,
      );
      expect(canPerform(ChatRecommendedAction.cancelTradeCompletionRequest), isFalse);
    });

    test('요청 거절·교환 완료 > 상대 활성 요청일 때만, 처리 대기 중 불가', () {
      for (final action in [
        ChatRecommendedAction.rejectTradeCompletionRequest,
        ChatRecommendedAction.confirmTradeCompletion,
      ]) {
        expect(canPerform(action, activeTradeRequestSenderId: opponentMemberId), isTrue, reason: action.name);
        expect(canPerform(action, activeTradeRequestSenderId: myMemberId), isFalse, reason: action.name);
        expect(canPerform(action), isFalse, reason: action.name);
        expect(
          canPerform(action, activeTradeRequestSenderId: opponentMemberId, isTradeActionPending: true),
          isFalse,
          reason: action.name,
        );
      }
    });
  });
}
