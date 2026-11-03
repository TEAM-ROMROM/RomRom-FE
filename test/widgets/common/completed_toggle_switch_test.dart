import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/widgets/common/completed_toggle_switch.dart';

import '../../helpers/pump_design_screen.dart';

/// 토글 스위치 접근성: 화면낭독기 이름·켜짐 상태, 확장 터치 여백 탭
void main() {
  testWidgets('화면낭독기에 이름과 켜짐 상태 노출', (tester) async {
    useDesignScreenView(tester);
    final semanticsHandle = tester.ensureSemantics();
    await tester.pumpWidget(
      buildDesignScreenApp(
        home: Scaffold(
          body: Center(
            child: CompletedToggleSwitch(value: true, onChanged: (_) {}, semanticLabel: '채팅 알림'),
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(CompletedToggleSwitch)),
      matchesSemantics(label: '채팅 알림', hasToggledState: true, isToggled: true, hasTapAction: true),
    );
    semanticsHandle.dispose();
  });

  testWidgets('확장 터치 여백 탭 > 반대 값 전달', (tester) async {
    useDesignScreenView(tester);
    bool? changedValue;
    await tester.pumpWidget(
      buildDesignScreenApp(
        home: Scaffold(
          body: Center(
            child: CompletedToggleSwitch(
              value: false,
              onChanged: (value) => changedValue = value,
              touchAreaPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ),
    );

    // 스위치 본체 밖 여백(왼쪽 위 모서리 근처) 탭
    final switchRect = tester.getRect(find.byType(CompletedToggleSwitch));
    await tester.tapAt(switchRect.topLeft + const Offset(4, 4));
    expect(changedValue, isTrue);
  });
}
