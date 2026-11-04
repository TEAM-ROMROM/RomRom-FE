import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/widgets/chat_room/chat_date_divider.dart';
import 'package:romrom_fe/widgets/chat_room/chat_room_message_list.dart';
import 'package:romrom_fe/widgets/chat_room/chat_unread_divider.dart';
import '../../helpers/pump_design_screen.dart';

/// 교환 요청·실패 메시지·후기 쓰기 콜백 호출 기록
class MessageListCallbackRecords {
  int cancelCount = 0;
  int rejectCount = 0;
  int confirmCount = 0;
  int writeReviewCount = 0;
  int retryOlderMessagesCount = 0;
  final List<String> retriedMessageIds = [];
  final List<String> deletedMessageIds = [];
}

/// 메시지 목록 렌더 (ScreenUtil 초기화 포함)
Future<MessageListCallbackRecords> pumpChatRoomMessageList(
  WidgetTester tester, {
  required List<ChatMessage> messages,
  String? lastReadMyMessageId,
  bool isTradeCompleted = false,
  Set<String> pendingLocalMessageIds = const {},
  Set<String> failedLocalMessageIds = const {},
  bool canWriteReview = false,
  bool hasOlderMessagesLoadFailed = false,
  String? firstUnreadMessageId,
}) async {
  useDesignScreenView(tester);
  final callbackCounts = MessageListCallbackRecords();
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
          pendingLocalMessageIds: pendingLocalMessageIds,
          failedLocalMessageIds: failedLocalMessageIds,
          isLoadingOlderMessages: false,
          hasOlderMessagesLoadFailed: hasOlderMessagesLoadFailed,
          onRetryOlderMessages: () => callbackCounts.retryOlderMessagesCount++,
          lastReadMyMessageId: lastReadMyMessageId,
          isTradeCompleted: isTradeCompleted,
          isTradeActionPending: false,
          onCancelTradeRequest: () => callbackCounts.cancelCount++,
          onRejectTradeRequest: () => callbackCounts.rejectCount++,
          onConfirmTradeRequest: () => callbackCounts.confirmCount++,
          onRetryFailedMessage: callbackCounts.retriedMessageIds.add,
          onDeleteFailedMessage: callbackCounts.deletedMessageIds.add,
          onWriteReview: canWriteReview ? () => callbackCounts.writeReviewCount++ : null,
          firstUnreadMessageId: firstUnreadMessageId,
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

    testWidgets('날짜가 바뀌는 지점마다 날짜 구분선 (같은 날은 1개)', (tester) async {
      await pumpChatRoomMessageList(
        tester,
        messages: [
          ChatMessage(
            chatMessageId: 'm3',
            senderId: 'me',
            type: MessageType.text,
            createdDate: DateTime(2026, 11, 1, 9),
          ),
          ChatMessage(
            chatMessageId: 'm2',
            senderId: 'me',
            type: MessageType.text,
            createdDate: DateTime(2026, 11, 1, 8),
          ),
          ChatMessage(
            chatMessageId: 'm1',
            senderId: 'other',
            type: MessageType.text,
            createdDate: DateTime(2026, 10, 31, 23, 59),
          ),
        ],
      );

      expect(find.byType(ChatDateDivider), findsNWidgets(2));
      expect(find.text('2026년 11월 1일 일요일'), findsOneWidget);
      expect(find.text('2026년 10월 31일 토요일'), findsOneWidget);
    });

    testWidgets('전송 중 메시지 > 전송 중 문구, 시각·읽음 대신 표시', (tester) async {
      await pumpChatRoomMessageList(
        tester,
        messages: [ChatMessage(chatMessageId: 'local_1', senderId: 'me', type: MessageType.text, content: '안녕')],
        pendingLocalMessageIds: {'local_1'},
        lastReadMyMessageId: 'local_1',
      );

      expect(find.text('전송 중'), findsOneWidget);
      expect(find.text('읽음'), findsNothing);
    });

    testWidgets('실패 메시지 > 다시 보내기·삭제가 해당 로컬 ID로 콜백 호출', (tester) async {
      final callbackCounts = await pumpChatRoomMessageList(
        tester,
        messages: [ChatMessage(chatMessageId: 'local_1', senderId: 'me', type: MessageType.text, content: '안녕')],
        pendingLocalMessageIds: {'local_1'},
        failedLocalMessageIds: {'local_1'},
      );

      expect(find.text('전송 실패'), findsOneWidget);
      await tester.tap(find.text('다시 보내기'));
      await tester.tap(find.text('삭제'));

      expect(callbackCounts.retriedMessageIds, ['local_1']);
      expect(callbackCounts.deletedMessageIds, ['local_1']);
    });

    testWidgets('교환 완료 카드 > 후기 작성 가능하면 후기 쓰기 버튼, 아니면 숨김', (tester) async {
      final completedMessages = [ChatMessage(chatMessageId: 'c1', senderId: 'other', type: MessageType.tradeCompleted)];
      final callbackCounts = await pumpChatRoomMessageList(
        tester,
        messages: completedMessages,
        isTradeCompleted: true,
        canWriteReview: true,
      );

      await tester.tap(find.text('후기 쓰기'));
      expect(callbackCounts.writeReviewCount, 1);

      await pumpChatRoomMessageList(tester, messages: completedMessages, isTradeCompleted: true);
      expect(find.text('후기 쓰기'), findsNothing);
    });

    testWidgets('이전 메시지 조회 실패 > 목록 맨 위 다시 불러오기 행이 재조회 콜백 호출', (tester) async {
      final callbackCounts = await pumpChatRoomMessageList(
        tester,
        messages: [ChatMessage(chatMessageId: 'm1', senderId: 'other', type: MessageType.text, content: '안녕')],
        hasOlderMessagesLoadFailed: true,
      );

      await tester.tap(find.text('이전 메시지를 불러오지 못했어요 · 다시 불러오기'));

      expect(callbackCounts.retryOlderMessagesCount, 1);
    });

    testWidgets('안 읽은 첫 메시지 위에만 여기까지 읽었어요 구분선 (#987), 없으면 미노출', (tester) async {
      final messages = [
        ChatMessage(chatMessageId: 'm3', senderId: 'other', type: MessageType.text, content: '세번째'),
        ChatMessage(chatMessageId: 'm2', senderId: 'other', type: MessageType.text, content: '두번째'),
        ChatMessage(chatMessageId: 'm1', senderId: 'me', type: MessageType.text, content: '첫번째'),
      ];
      await pumpChatRoomMessageList(tester, messages: messages, firstUnreadMessageId: 'm2');

      expect(find.text(ChatUnreadDivider.label), findsOneWidget);
      // 구분선이 읽은 메시지(m1)와 첫 안 읽은 메시지(m2) 사이 (reverse 목록 > 화면 위쪽이 오래된 메시지)
      final dividerTop = tester.getTopLeft(find.byType(ChatUnreadDivider)).dy;
      expect(tester.getTopLeft(find.text('첫번째')).dy, lessThan(dividerTop));
      expect(tester.getTopLeft(find.text('두번째')).dy, greaterThan(dividerTop));

      await pumpChatRoomMessageList(tester, messages: messages);
      expect(find.byType(ChatUnreadDivider), findsNothing);
    });
  });
}
