import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/widgets/chat_room/chat_scroll_to_latest_button.dart';
import '../../helpers/pump_design_screen.dart';

/// 맨 아래로 버튼 (#987): 새 메시지 있으면 '새 메시지 N' 알약, 숨김 상태는 탭 무시
void main() {
  Future<List<int>> pumpButton(WidgetTester tester, {required bool isVisible, required int unseenCount}) async {
    useDesignScreenView(tester);
    final pressedRecords = <int>[];
    await tester.pumpWidget(
      buildDesignScreenApp(
        home: Scaffold(
          body: Center(
            child: ChatScrollToLatestButton(
              isVisible: isVisible,
              unseenMessageCount: unseenCount,
              onPressed: () => pressedRecords.add(unseenCount),
            ),
          ),
        ),
      ),
    );
    return pressedRecords;
  }

  testWidgets('새 메시지 3개 > 알약 문구, 탭 > 콜백', (tester) async {
    final pressedRecords = await pumpButton(tester, isVisible: true, unseenCount: 3);

    expect(find.text('새 메시지 3'), findsOneWidget);
    await tester.tap(find.byType(ChatScrollToLatestButton));
    expect(pressedRecords, [3]);
  });

  testWidgets('새 메시지 없음 > 화살표만', (tester) async {
    await pumpButton(tester, isVisible: true, unseenCount: 0);

    expect(find.textContaining('새 메시지'), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
  });

  testWidgets('맨 아래 근처(숨김) > 탭 무시', (tester) async {
    final pressedRecords = await pumpButton(tester, isVisible: false, unseenCount: 2);

    await tester.tap(find.byType(ChatScrollToLatestButton), warnIfMissed: false);
    expect(pressedRecords, isEmpty);
  });
}
