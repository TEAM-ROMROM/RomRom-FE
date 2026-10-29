import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/widgets/chat_message_item.dart';
import '../helpers/pump_design_screen.dart';

/// 상대방이 보낸 활성 교환 완료 요청 카드 렌더
Future<void> pumpOpponentTradeRequestCard(
  WidgetTester tester, {
  required bool isTradeActionPending,
  required VoidCallback onRejectTradeRequest,
  required VoidCallback onConfirmTradeRequest,
}) async {
  useDesignScreenView(tester);

  await tester.pumpWidget(
    buildDesignScreenApp(
      home: Scaffold(
        body: ChatMessageItem(
          message: ChatMessage(senderId: 'opponent', type: MessageType.tradeCompleteRequest),
          myMemberId: 'me',
          topGap: 0,
          showTime: false,
          isUploading: false,
          opponentNickname: '상대',
          onRejectTradeRequest: onRejectTradeRequest,
          onConfirmTradeRequest: onConfirmTradeRequest,
          isTradeActionPending: isTradeActionPending,
        ),
      ),
    ),
  );
}

void main() {
  group('ChatMessageItem 교환 완료 요청 버튼', () {
    testWidgets('진행 중 아님 > 거절·완료 탭 시 콜백 호출', (tester) async {
      var rejectCallCount = 0;
      var confirmCallCount = 0;
      await pumpOpponentTradeRequestCard(
        tester,
        isTradeActionPending: false,
        onRejectTradeRequest: () => rejectCallCount++,
        onConfirmTradeRequest: () => confirmCallCount++,
      );

      await tester.tap(find.text('거절하기'));
      await tester.tap(find.text('확인 및 완료하기'));

      expect(rejectCallCount, 1);
      expect(confirmCallCount, 1);
    });

    testWidgets('진행 중 > 거절·완료 탭 무시', (tester) async {
      var rejectCallCount = 0;
      var confirmCallCount = 0;
      await pumpOpponentTradeRequestCard(
        tester,
        isTradeActionPending: true,
        onRejectTradeRequest: () => rejectCallCount++,
        onConfirmTradeRequest: () => confirmCallCount++,
      );

      await tester.tap(find.text('거절하기'));
      await tester.tap(find.text('확인 및 완료하기'));

      expect(rejectCallCount, 0);
      expect(confirmCallCount, 0);
    });
  });
}
