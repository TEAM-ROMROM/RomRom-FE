import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:romrom_fe/widgets/home_tab/home_feed_native_ad_handle.dart';
import 'package:romrom_fe/widgets/home_tab/home_feed_native_ad_preloader.dart';

/// 광고 요청 결과 대역 (플랫폼 호출 없음, 폐기 횟수 기록)
class _FakeNativeAdHandle extends HomeFeedNativeAdHandle {
  _FakeNativeAdHandle({required Completer<bool> loadCompleter, required super.requestedAt})
    : super(
        nativeAd: NativeAd(
          adUnitId: 'test',
          factoryId: 'test',
          listener: NativeAdListener(),
          request: const AdRequest(),
        ),
        isLoadedFuture: loadCompleter.future,
      );

  int disposeCount = 0;

  @override
  void dispose() => disposeCount++;
}

/// 홈 피드 광고 미리 받기: 1개만 보관, 광고 칸이 가져감, 실패·오래된 광고 폐기
void main() {
  late DateTime currentTime;
  late List<_FakeNativeAdHandle> requestedHandles;
  late Completer<bool> nextLoadCompleter;

  HomeFeedNativeAdHandle requestFakeAd() {
    final handle = _FakeNativeAdHandle(loadCompleter: nextLoadCompleter, requestedAt: currentTime);
    requestedHandles.add(handle);
    return handle;
  }

  HomeFeedNativeAdPreloader buildPreloader() => HomeFeedNativeAdPreloader(now: () => currentTime);

  setUp(() {
    currentTime = DateTime(2026, 11, 3, 12);
    requestedHandles = [];
    nextLoadCompleter = Completer<bool>();
  });

  test('preload: 보관 중이면 다시 요청하지 않음 > 광고 칸이 가져가면 다음 요청 가능', () {
    final preloader = buildPreloader();

    preloader.preload(requestFakeAd);
    preloader.preload(requestFakeAd);
    expect(requestedHandles.length, 1);

    expect(preloader.takePreloadedAd(), same(requestedHandles.single));
    expect(preloader.takePreloadedAd(), isNull, reason: '한 번 가져가면 비움');

    nextLoadCompleter = Completer<bool>();
    preloader.preload(requestFakeAd);
    expect(requestedHandles.length, 2);
  });

  test('광고 ID 없음(요청 결과 null) > 보관 없음', () {
    final preloader = buildPreloader();

    preloader.preload(() => null);

    expect(preloader.takePreloadedAd(), isNull);
  });

  test('로드 실패 > 보관 비움, 다음 preload에서 다시 요청', () async {
    final preloader = buildPreloader();
    preloader.preload(requestFakeAd);

    nextLoadCompleter.complete(false);
    await Future<void>.delayed(Duration.zero);
    nextLoadCompleter = Completer<bool>();
    preloader.preload(requestFakeAd);

    expect(requestedHandles.length, 2);
    expect(preloader.takePreloadedAd(), same(requestedHandles.last));
  });

  test('오래된 광고(최대 보관 시간 초과) > 폐기 후 null', () {
    final preloader = buildPreloader();
    preloader.preload(requestFakeAd);

    currentTime = currentTime.add(HomeFeedNativeAdPreloader.maximumPreloadedAdAge + const Duration(seconds: 1));

    expect(preloader.takePreloadedAd(), isNull);
    expect(requestedHandles.single.disposeCount, 1);
  });

  test('dispose: 보관 중 광고 폐기', () {
    final preloader = buildPreloader();
    preloader.preload(requestFakeAd);

    preloader.dispose();

    expect(requestedHandles.single.disposeCount, 1);
    expect(preloader.takePreloadedAd(), isNull);
  });
}
