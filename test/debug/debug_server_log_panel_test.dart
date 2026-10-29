import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/debug/log_capture.dart';
import 'package:romrom_fe/debug/server_log_client.dart';
import 'package:romrom_fe/debug/widgets/debug_server_log_panel.dart';
import '../helpers/pump_design_screen.dart';

/// 서버 로그 클라이언트 대역: 연결 상태 수동 변경 + 로그 수동 발행 (실제 WebSocket 없음)
class FakeServerLogClient implements ServerLogClient {
  final StreamController<CapturedLog> logStreamController = StreamController<CapturedLog>.broadcast();
  final List<CapturedLog> bufferedLogs = [];
  bool isConnectedValue = false;
  int connectCallCount = 0;

  /// 연결 상태 변경 후 시스템 로그 발행 (실제 클라이언트의 '[서버 로그] 연결 성공' 흐름 재현)
  void emitSystemLog(String message) {
    final log = CapturedLog(time: DateTime(2026, 10, 29, 12), message: message);
    bufferedLogs.add(log);
    logStreamController.add(log);
  }

  @override
  bool get isConnected => isConnectedValue;

  @override
  bool get isAopEnabled => false;

  @override
  List<CapturedLog> get logs => List.unmodifiable(bufferedLogs);

  @override
  Stream<CapturedLog> get stream => logStreamController.stream;

  @override
  Future<void> connect() async => connectCallCount++;

  @override
  void clear() => bufferedLogs.clear();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 연결 상태 점 색
Color? findConnectionDotColor(WidgetTester tester) {
  final connectionDot = tester.widget<Container>(
    find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
    ),
  );
  return (connectionDot.decoration! as BoxDecoration).color;
}

void main() {
  late FakeServerLogClient fakeServerLogClient;

  setUp(() => fakeServerLogClient = FakeServerLogClient());
  tearDown(() => fakeServerLogClient.logStreamController.close());

  testWidgets('연결 성공 로그 수신 시 연결 점·링크 아이콘 갱신 (패널 열릴 때 connect 1회)', (tester) async {
    useDesignScreenView(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [DebugServerLogPanel(onClose: () {}, onMinimize: () {}, serverLogClient: fakeServerLogClient)],
        ),
      ),
    );

    expect(fakeServerLogClient.connectCallCount, 1);
    expect(find.byIcon(Icons.link_off), findsOneWidget);
    expect(findConnectionDotColor(tester), Colors.red);

    // 연결 상태 변경 > 시스템 로그 발행 > 디바운스(100ms) 후 패널 rebuild
    fakeServerLogClient.isConnectedValue = true;
    fakeServerLogClient.emitSystemLog('[서버 로그] 연결 성공');
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byIcon(Icons.link), findsOneWidget);
    expect(find.byIcon(Icons.link_off), findsNothing);
    expect(findConnectionDotColor(tester), Colors.green);

    // 서버 쪽 연결 종료도 반영
    fakeServerLogClient.isConnectedValue = false;
    fakeServerLogClient.emitSystemLog('[서버 로그] 연결 종료');
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byIcon(Icons.link_off), findsOneWidget);
    expect(findConnectionDotColor(tester), Colors.red);
  });
}
