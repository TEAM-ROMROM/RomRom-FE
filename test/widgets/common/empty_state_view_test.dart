import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import '../../helpers/pump_design_screen.dart';

/// 테스트 앱 렌더 (ScreenUtil 초기화 포함)
Future<void> pumpEmptyStateView(WidgetTester tester, Widget emptyStateView) async {
  await tester.pumpWidget(buildDesignScreenApp(home: Scaffold(body: emptyStateView)));
}

void main() {
  group('EmptyStateView.error', () {
    testWidgets('기본 문구·경고 아이콘·다시 시도 버튼 렌더', (tester) async {
      await pumpEmptyStateView(tester, EmptyStateView.error(onRetry: () {}));

      expect(find.text('불러오지 못했어요'), findsOneWidget);
      expect(find.text('잠시 후 다시 시도해 주세요'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
      expect(find.byIcon(AppIcons.warning), findsOneWidget);
    });

    testWidgets('문구 지정 시 지정 문구 렌더', (tester) async {
      await pumpEmptyStateView(
        tester,
        EmptyStateView.error(onRetry: () {}, centerText: '채팅을 불러오지 못했어요', descriptionText: '네트워크를 확인해 주세요'),
      );

      expect(find.text('채팅을 불러오지 못했어요'), findsOneWidget);
      expect(find.text('네트워크를 확인해 주세요'), findsOneWidget);
    });

    testWidgets('다시 시도 탭 시 onRetry 1회 호출', (tester) async {
      var retryCallCount = 0;
      await pumpEmptyStateView(tester, EmptyStateView.error(onRetry: () => retryCallCount++));

      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();

      expect(retryCallCount, 1);
    });

    testWidgets('재시도 진행 중이면 스피너 표시 + 탭 무시', (tester) async {
      var retryCallCount = 0;
      await pumpEmptyStateView(tester, EmptyStateView.error(onRetry: () => retryCallCount++, isRetrying: true));

      expect(find.text('다시 시도'), findsNothing);
      expect(find.byType(CommonLoadingIndicator), findsOneWidget);

      await tester.tap(find.byType(CommonLoadingIndicator));
      await tester.pump();

      expect(retryCallCount, 0);
    });
  });
}
