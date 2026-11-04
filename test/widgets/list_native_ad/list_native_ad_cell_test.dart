import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/services/native_ad_handle.dart';
import 'package:romrom_fe/widgets/list_native_ad/list_native_ad_cell.dart';

import '../../helpers/native_ad_fakes.dart';
import '../../helpers/pump_design_screen.dart';

/// 목록 광고 칸: 로드 중 자리 확보, 광고 없음·실패 > 높이 0 (구분선 포함), 종료 시 폐기
void main() {
  const separatorKey = ValueKey('ad_bottom_separator');
  const cellKey = ValueKey('list_native_ad_cell');

  late Completer<bool> loadCompleter;
  late NativeAdHandle requestedHandle;

  // 완료 알림이 테스트 시간(fake async) 안에서 흐르도록 위젯 빌드 중 생성
  NativeAdHandle requestFakeAd(BuildContext context) {
    loadCompleter = Completer<bool>();
    requestedHandle = NativeAdHandle(
      nativeAd: buildTestNativeAd(),
      isLoadedFuture: loadCompleter.future,
      requestedAt: DateTime(2026, 11, 4),
    );
    return requestedHandle;
  }

  Widget buildCellApp(NativeAdHandle? Function(BuildContext context) requestAd) {
    return buildDesignScreenApp(
      home: Scaffold(
        body: Column(
          children: [
            ListNativeAdCell(
              key: cellKey,
              requestAd: requestAd,
              bottomSeparator: const SizedBox(key: separatorKey, height: 8),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('로드 중 > 광고 칸 높이 확보 (행 밀림 방지)', (tester) async {
    useDesignScreenView(tester);
    await tester.pumpWidget(buildCellApp(requestFakeAd));

    expect(tester.getSize(find.byKey(cellKey)).height, greaterThan(0));
    expect(find.byKey(separatorKey), findsOneWidget);
  });

  testWidgets('로드 실패 > 높이 0으로 접힘, 아래 구분선도 사라짐', (tester) async {
    useDesignScreenView(tester);
    await tester.pumpWidget(buildCellApp(requestFakeAd));

    loadCompleter.complete(false);
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byKey(cellKey)).height, 0);
    expect(find.byKey(separatorKey), findsNothing);
  });

  testWidgets('광고 ID 없음(요청 결과 null) > 처음부터 높이 0', (tester) async {
    useDesignScreenView(tester);
    await tester.pumpWidget(buildCellApp((_) => null));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byKey(cellKey)).height, 0);
  });

  testWidgets('칸 종료 > 광고 폐기', (tester) async {
    useDesignScreenView(tester);
    await tester.pumpWidget(buildCellApp(requestFakeAd));

    await tester.pumpWidget(const SizedBox.shrink());

    expect(requestedHandle.isDisposed, isTrue);
  });
}
