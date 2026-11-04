import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:romrom_fe/services/native_ad_handle.dart';
import 'package:romrom_fe/widgets/home_tab/home_feed_native_ad_preloader.dart';
import 'package:romrom_fe/widgets/native_ad_widget.dart';

import '../helpers/pump_design_screen.dart';

/// 홈 피드 광고 칸: 보관소에서 빌리고 종료 시 반납만 (폐기 안 함), 실패 > 칸 접기 알림
void main() {
  late List<Completer<bool>> loadCompleters;
  late List<NativeAdHandle> requestedHandles;

  // 완료 알림이 테스트 시간(fake async) 안에서 흐르도록 위젯 빌드 중 생성
  NativeAdHandle requestFakeAd(BuildContext context) {
    final loadCompleter = Completer<bool>();
    final handle = NativeAdHandle(
      nativeAd: NativeAd(adUnitId: 'test', factoryId: 'test', listener: NativeAdListener(), request: const AdRequest()),
      isLoadedFuture: loadCompleter.future,
      requestedAt: DateTime.now(),
    );
    loadCompleters.add(loadCompleter);
    requestedHandles.add(handle);
    return handle;
  }

  Widget buildAdPage(HomeFeedNativeAdPreloader adPreloader, {VoidCallback? onLoadFailed}) {
    return buildDesignScreenApp(
      home: NativeAdWidget(
        adVirtualIndex: 5,
        adPreloader: adPreloader,
        onLoadFailed: onLoadFailed,
        requestAd: requestFakeAd,
      ),
    );
  }

  setUp(() {
    loadCompleters = [];
    requestedHandles = [];
  });

  testWidgets('칸이 화면에서 빠져도 광고 폐기 안 함 > 다시 그리면 같은 광고 (재요청 없음)', (tester) async {
    useDesignScreenView(tester);
    final adPreloader = HomeFeedNativeAdPreloader();
    addTearDown(adPreloader.dispose);

    await tester.pumpWidget(buildAdPage(adPreloader));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(buildAdPage(adPreloader));

    expect(requestedHandles.length, 1);
    expect(requestedHandles.single.isDisposed, isFalse);
  });

  testWidgets('로드 실패 > 칸 접기 알림 1회', (tester) async {
    useDesignScreenView(tester);
    final adPreloader = HomeFeedNativeAdPreloader();
    addTearDown(adPreloader.dispose);
    var loadFailedCount = 0;

    await tester.pumpWidget(buildAdPage(adPreloader, onLoadFailed: () => loadFailedCount++));
    loadCompleters.single.complete(false);
    await tester.pump();
    await tester.pump();

    expect(loadFailedCount, 1);
  });
}
