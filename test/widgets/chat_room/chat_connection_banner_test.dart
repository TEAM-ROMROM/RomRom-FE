import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/widgets/chat_room/chat_connection_banner.dart';
import '../../helpers/pump_design_screen.dart';

/// '연결 중…' 띠 (#987): 끊김이 대기 시간 넘게 이어질 때만 노출, 연결되면 즉시 숨김
void main() {
  late ValueNotifier<bool> connectionStatus;

  setUp(() => connectionStatus = ValueNotifier<bool>(true));
  tearDown(() => connectionStatus.dispose());

  Future<void> pumpBanner(WidgetTester tester) async {
    useDesignScreenView(tester);
    await tester.pumpWidget(
      buildDesignScreenApp(
        home: Scaffold(body: ChatConnectionBanner(connectionStatus: connectionStatus)),
      ),
    );
  }

  testWidgets('연결 상태 > 띠 없음', (tester) async {
    await pumpBanner(tester);
    await tester.pump(ChatConnectionBanner.disconnectedGraceDuration * 2);

    expect(find.text('연결 중…'), findsNothing);
  });

  testWidgets('끊김 > 대기 시간 전엔 숨김, 지나면 노출 > 재연결 시 숨김', (tester) async {
    await pumpBanner(tester);

    connectionStatus.value = false;
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('연결 중…'), findsNothing, reason: '순간 재연결 깜빡임 방지');

    await tester.pump(ChatConnectionBanner.disconnectedGraceDuration);
    expect(find.text('연결 중…'), findsOneWidget);

    connectionStatus.value = true;
    await tester.pumpAndSettle();
    expect(find.text('연결 중…'), findsNothing);
  });

  testWidgets('대기 중 다시 연결 > 띠 노출 안 함', (tester) async {
    await pumpBanner(tester);

    connectionStatus.value = false;
    await tester.pump(const Duration(milliseconds: 300));
    connectionStatus.value = true;
    await tester.pump(ChatConnectionBanner.disconnectedGraceDuration * 2);

    expect(find.text('연결 중…'), findsNothing);
  });

  testWidgets('진입 시 이미 끊김 > 대기 후 노출', (tester) async {
    connectionStatus.value = false;
    await pumpBanner(tester);
    await tester.pump(ChatConnectionBanner.disconnectedGraceDuration);

    expect(find.text('연결 중…'), findsOneWidget);
  });
}
