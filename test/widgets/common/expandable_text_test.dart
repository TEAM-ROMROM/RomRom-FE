import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/widgets/common/expandable_text.dart';

import '../../helpers/pump_design_screen.dart';

/// 펼치기 텍스트: 넘치면 탭으로 펼치기·접기, 안 넘치면 탭 없음
void main() {
  Text findBodyText(WidgetTester tester, String text) => tester.widget<Text>(find.text(text));

  testWidgets('넘치는 본문 > 탭하면 전체, 다시 탭하면 접기', (tester) async {
    useDesignScreenView(tester);
    final longText = List.filled(40, '공지 본문입니다').join(' ');
    await tester.pumpWidget(
      buildDesignScreenApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: ExpandableText(text: longText, style: const TextStyle(fontSize: 14)),
          ),
        ),
      ),
    );

    expect(findBodyText(tester, longText).maxLines, 2);

    await tester.tap(find.text(longText));
    await tester.pumpAndSettle();
    expect(findBodyText(tester, longText).maxLines, isNull);

    await tester.tap(find.text(longText));
    await tester.pumpAndSettle();
    expect(findBodyText(tester, longText).maxLines, 2);
  });

  testWidgets('짧은 본문 > 펼치기 표시 없음, 부모 탭 전달', (tester) async {
    useDesignScreenView(tester);
    var parentTapCount = 0;
    await tester.pumpWidget(
      buildDesignScreenApp(
        home: Scaffold(
          body: GestureDetector(
            onTap: () => parentTapCount++,
            child: const SizedBox(
              width: 300,
              child: ExpandableText(text: '짧은 공지', style: TextStyle(fontSize: 14)),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
    await tester.tap(find.text('짧은 공지'));
    expect(parentTapCount, 1);
  });

  testWidgets('화살표만 펼치기(isToggleOnArrowOnly) > 본문 탭은 부모로, 화살표 탭은 펼치기', (tester) async {
    useDesignScreenView(tester);
    var parentTapCount = 0;
    final longText = List.filled(40, '공지 본문입니다').join(' ');
    await tester.pumpWidget(
      buildDesignScreenApp(
        home: Scaffold(
          body: GestureDetector(
            onTap: () => parentTapCount++,
            child: SizedBox(
              width: 200,
              child: ExpandableText(text: longText, style: const TextStyle(fontSize: 14), isToggleOnArrowOnly: true),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text(longText));
    await tester.pumpAndSettle();
    expect(parentTapCount, 1);
    expect(findBodyText(tester, longText).maxLines, 2);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pumpAndSettle();
    expect(parentTapCount, 1);
    expect(findBodyText(tester, longText).maxLines, isNull);
  });
}
