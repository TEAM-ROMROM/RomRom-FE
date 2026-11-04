import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/utils/reverse_list_scroll_to_item.dart';
import 'package:romrom_fe/widgets/chat_room/chat_room_message_list.dart';
import 'package:romrom_fe/widgets/chat_room/chat_unread_divider.dart';
import '../../helpers/pump_design_screen.dart';

/// 진입 시 안 읽은 위치 이동 (#987): 화면 밖(렌더 전) 구분선까지 넘겨 찾고 화면 위쪽에 맞춤, 가까우면 맨 아래 유지
void main() {
  // reverse 목록 (index 0 = 최신), 같은 날짜 > 날짜 구분선은 맨 위 1개
  final createdDate = DateTime(2026, 11, 4, 12);
  final messages = [
    for (var index = 0; index < 200; index++)
      ChatMessage(
        chatMessageId: 'm$index',
        senderId: index.isEven ? 'other' : 'me',
        type: MessageType.text,
        content: '메시지 $index',
        createdDate: createdDate,
      ),
  ];

  Future<(ScrollController, GlobalKey)> pumpList(WidgetTester tester, {required String firstUnreadMessageId}) async {
    useDesignScreenView(tester);
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    final dividerKey = GlobalKey();
    await tester.pumpWidget(
      buildDesignScreenApp(
        home: Scaffold(
          body: ChatRoomMessageList(
            messages: messages,
            scrollController: scrollController,
            myMemberId: 'me',
            opponentNickname: '상대',
            uploadingMessageIds: const {},
            pendingLocalMessageIds: const {},
            failedLocalMessageIds: const {},
            isLoadingOlderMessages: false,
            hasOlderMessagesLoadFailed: false,
            onRetryOlderMessages: () {},
            lastReadMyMessageId: null,
            isTradeCompleted: false,
            isTradeActionPending: false,
            onCancelTradeRequest: () {},
            onRejectTradeRequest: () {},
            onConfirmTradeRequest: () {},
            onRetryFailedMessage: (_) {},
            onDeleteFailedMessage: (_) {},
            onWriteReview: null,
            firstUnreadMessageId: firstUnreadMessageId,
            unreadDividerKey: dividerKey,
          ),
        ),
      ),
    );
    return (scrollController, dividerKey);
  }

  /// 이동 실행 (프레임 진행하며 완료 대기)
  Future<bool> runScroll(WidgetTester tester, ScrollController scrollController, GlobalKey dividerKey) async {
    final scrolling = scrollReverseListToKeyedItem(
      scrollController: scrollController,
      itemKey: dividerKey,
      alignment: 0.85,
      maximumAttemptCount: 20,
      isActive: () => true,
    );
    for (var frame = 0; frame < 25; frame++) {
      await tester.pump();
    }
    return scrolling;
  }

  testWidgets('먼 위쪽(렌더 전) 구분선 > 위로 넘겨 찾고 화면 위쪽에 표시', (tester) async {
    final (scrollController, dividerKey) = await pumpList(tester, firstUnreadMessageId: 'm150');
    expect(find.byType(ChatUnreadDivider), findsNothing, reason: '처음엔 맨 아래라 구분선 렌더 전');

    expect(await runScroll(tester, scrollController, dividerKey), isTrue);

    final dividerTop = tester.getTopLeft(find.byType(ChatUnreadDivider)).dy;
    expect(dividerTop, lessThan(designScreenSize.height * 0.3), reason: '구분선이 화면 위쪽');
    expect(find.text('메시지 150'), findsOneWidget, reason: '첫 안 읽은 메시지 바로 보임');
  });

  testWidgets('구분선이 이미 화면 안(맨 아래 근처) > 맨 아래 유지 (범위 밖 이동 없음)', (tester) async {
    final (scrollController, dividerKey) = await pumpList(tester, firstUnreadMessageId: 'm0');

    expect(await runScroll(tester, scrollController, dividerKey), isTrue);

    expect(scrollController.offset, 0);
  });
}
