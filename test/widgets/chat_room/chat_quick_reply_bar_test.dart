import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/chat_quick_replies.dart';
import 'package:romrom_fe/utils/chat_input_convenience_rules.dart';
import 'package:romrom_fe/widgets/chat_room/chat_quick_reply_bar.dart';
import '../../helpers/pump_design_screen.dart';

/// 빠른 답장 줄 (#987): 노출 시 원본 문구 칩, 탭 > 입력창에 넣기만 (전송 없음)
void main() {
  testWidgets('칩 탭 > 입력창에 문구 들어감, 전송 콜백 없음', (tester) async {
    useDesignScreenView(tester);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var sendCount = 0;

    await tester.pumpWidget(
      buildDesignScreenApp(
        home: Scaffold(
          body: Column(
            children: [
              ChatQuickReplyBar(
                isVisible: true,
                onPhraseSelected: (phrase) =>
                    controller.value = applyQuickReplyToInput(currentValue: controller.value, phrase: phrase),
              ),
              TextField(controller: controller, onSubmitted: (_) => sendCount++),
            ],
          ),
        ),
      ),
    );

    final phrase = chatQuickReplyPhrases[1];
    await tester.tap(find.text(phrase));
    await tester.pump();

    expect(controller.text, phrase);
    expect(sendCount, 0);
  });

  testWidgets('숨김 > 칩 없음', (tester) async {
    useDesignScreenView(tester);
    await tester.pumpWidget(
      buildDesignScreenApp(
        home: Scaffold(body: ChatQuickReplyBar(isVisible: false, onPhraseSelected: (_) {})),
      ),
    );

    for (final phrase in chatQuickReplyPhrases) {
      expect(find.text(phrase), findsNothing);
    }
  });
}
