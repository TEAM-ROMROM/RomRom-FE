import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/widgets/chat_room/chat_room_message_list.dart';
import '../../helpers/pump_design_screen.dart';

/// 교환 요청 버튼 콜백 호출 횟수
class TradeRequestCallbackCounts {
  int cancelCount = 0;
  int rejectCount = 0;
  int confirmCount = 0;
}

/// 메시지 목록 렌더 (ScreenUtil 초기화 포함)
Future<TradeRequestCallbackCounts> pumpChatRoomMessageList(
  WidgetTester tester, {
  required List<ChatMessage> messages,
  String? lastReadMyMessageId,
  bool isTradeCompleted = false,
}) async {
  useDesignScreenView(tester);
  final callbackCounts = TradeRequestCallbackCounts();
  final scrollController = ScrollController();
  addTearDown(scrollController.dispose);

  await tester.pumpWidget(
    buildDesignScreenApp(
      home: Scaffold(
        body: ChatRoomMessageList(
          messages: messages,
          scrollController: scrollController,
          myMemberId: 'me',
          opponentNickname: '상대',
          uploadingMessageIds: const {},
          lastReadMyMessageId: lastReadMyMessageId,
          isTradeCompleted: isTradeCompleted,
          isTradeActionPending: false,
          onCancelTradeRequest: () => callbackCounts.cancelCount++,
          onRejectTradeRequest: () => callbackCounts.rejectCount++,
          onConfirmTradeRequest: () => callbackCounts.confirmCount++,
        ),
      ),
    ),
  );
  return callbackCounts;
}

void main() {
  group('ChatRoomMessageList', () {
    testWidgets('빈 목록 > 안내 문구', (tester) async {
      await pumpChatRoomMessageList(tester, messages: const []);

      expect(find.text('메시지를 입력해보세요'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('상대의 활성 교환 요청 > 거절·완료 버튼이 화면 콜백 호출', (tester) async {
      final callbackCounts = await pumpChatRoomMessageList(
        tester,
        messages: [ChatMessage(chatMessageId: 'r1', senderId: 'other', type: MessageType.tradeCompleteRequest)],
      );

      await tester.tap(find.text('거절하기'));
      await tester.tap(find.text('확인 및 완료하기'));

      expect(callbackCounts.rejectCount, 1);
      expect(callbackCounts.confirmCount, 1);
      expect(callbackCounts.cancelCount, 0);
    });

    testWidgets('내 활성 교환 요청 > 요청 취소 버튼', (tester) async {
      final callbackCounts = await pumpChatRoomMessageList(
        tester,
        messages: [ChatMessage(chatMessageId: 'r1', senderId: 'me', type: MessageType.tradeCompleteRequest)],
      );

      await tester.tap(find.text('요청 취소하기'));

      expect(callbackCounts.cancelCount, 1);
    });

    testWidgets('거절된 교환 요청 > 버튼 없음', (tester) async {
      await pumpChatRoomMessageList(
        tester,
        messages: [
          ChatMessage(chatMessageId: 'x1', senderId: 'me', type: MessageType.tradeCompleteRequestRejected),
          ChatMessage(chatMessageId: 'r1', senderId: 'other', type: MessageType.tradeCompleteRequest),
        ],
      );

      expect(find.text('거절하기'), findsNothing);
      expect(find.text('확인 및 완료하기'), findsNothing);
    });

    testWidgets('읽음 표시는 lastReadMyMessageId 메시지에만', (tester) async {
      final sentAt = DateTime(2026, 10, 29, 12);
      await pumpChatRoomMessageList(
        tester,
        messages: [
          ChatMessage(chatMessageId: 'm2', senderId: 'me', type: MessageType.text, content: '둘', createdDate: sentAt),
          ChatMessage(chatMessageId: 'm1', senderId: 'me', type: MessageType.text, content: '하나', createdDate: sentAt),
        ],
        lastReadMyMessageId: 'm2',
      );

      expect(find.text('읽음'), findsOneWidget);
    });
  });
}
