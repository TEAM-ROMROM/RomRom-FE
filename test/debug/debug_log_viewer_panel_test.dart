import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/debug/log_capture.dart';
import 'package:romrom_fe/debug/widgets/debug_log_panel.dart';
import 'package:romrom_fe/debug/widgets/debug_log_viewer_panel.dart';
import '../helpers/pump_design_screen.dart';

/// 패널 렌더 (오버레이와 같은 Stack 안)
Future<void> pumpPanel(WidgetTester tester, Widget panel) async {
  useDesignScreenView(tester);
  await tester.pumpWidget(MaterialApp(home: Stack(children: [panel])));
}

/// 패널 외곽 박스 크기
Size findPanelSize(WidgetTester tester) {
  final panelBox = find.descendant(of: find.byType(Positioned), matching: find.byType(Container)).first;
  return tester.getSize(panelBox);
}

void main() {
  group('DebugLogViewerPanel', () {
    late List<CapturedLog> bufferedLogs;
    late StreamController<CapturedLog> logStreamController;
    late int clearCallCount;

    setUp(() {
      bufferedLogs = [];
      logStreamController = StreamController<CapturedLog>.broadcast();
      clearCallCount = 0;
    });

    tearDown(() => logStreamController.close());

    DebugLogViewerPanel buildPanel({List<Widget> Function()? buildTitleBarActions}) {
      return DebugLogViewerPanel(
        title: '서버 로그',
        emptyLogText: '서버 로그 없음',
        readLogs: () => bufferedLogs,
        logStream: logStreamController.stream,
        clearLogs: () {
          clearCallCount++;
          bufferedLogs.clear();
        },
        buildTitleBarActions: buildTitleBarActions,
        onClose: () {},
        onMinimize: () {},
      );
    }

    testWidgets('제목·빈 문구 렌더, 첫 크기 = 화면 너비 90%·높이 50%', (tester) async {
      await pumpPanel(tester, buildPanel());

      expect(find.text('서버 로그'), findsOneWidget);
      expect(find.text('서버 로그 없음'), findsOneWidget);
      expect(find.text('0건'), findsOneWidget);
      final panelSize = findPanelSize(tester);
      expect(panelSize.width, closeTo(designScreenSize.width * 0.9, 0.01));
      expect(panelSize.height, closeTo(designScreenSize.height * 0.5, 0.01));
    });

    testWidgets('버퍼 로그 HH:mm:ss 시각과 함께 표시, 클리어 시 비움', (tester) async {
      bufferedLogs.add(CapturedLog(time: DateTime(2026, 10, 29, 9, 5, 7), message: 'hello'));
      await pumpPanel(tester, buildPanel());

      expect(find.textContaining('09:05:07', findRichText: true), findsOneWidget);
      expect(find.textContaining('hello', findRichText: true), findsOneWidget);
      expect(find.text('1건'), findsOneWidget);

      await tester.tap(find.text('클리어'));
      await tester.pump();
      expect(clearCallCount, 1);
      expect(find.text('서버 로그 없음'), findsOneWidget);
    });

    testWidgets('추가 버튼은 필터 버튼 앞에 배치', (tester) async {
      await pumpPanel(
        tester,
        buildPanel(
          buildTitleBarActions: () => [DebugTitleBarButton(icon: Icons.link, onTap: () {})],
        ),
      );

      final linkButtonLeft = tester.getTopLeft(find.byIcon(Icons.link)).dx;
      final filterButtonLeft = tester.getTopLeft(find.byIcon(Icons.filter_list)).dx;
      expect(linkButtonLeft, lessThan(filterButtonLeft));
    });

    testWidgets('리사이즈 핸들로 줄여도 최소 280x200 유지', (tester) async {
      await pumpPanel(tester, buildPanel());

      await tester.drag(find.byIcon(Icons.drag_handle), const Offset(-1000, -1000));
      await tester.pump();

      final panelSize = findPanelSize(tester);
      expect(panelSize.width, 280);
      expect(panelSize.height, 200);
    });
  });

  testWidgets('DebugLogPanel: 앱 로그 제목·빈 문구', (tester) async {
    LogCapture().clear();
    await pumpPanel(tester, DebugLogPanel(onClose: () {}, onMinimize: () {}));

    expect(find.text('로그 뷰어'), findsOneWidget);
    expect(find.text('로그 없음'), findsOneWidget);
  });
}
