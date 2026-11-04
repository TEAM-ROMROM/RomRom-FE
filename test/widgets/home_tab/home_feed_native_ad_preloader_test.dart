import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:romrom_fe/services/native_ad_handle.dart';
import 'package:romrom_fe/widgets/home_tab/home_feed_native_ad_preloader.dart';

/// 광고 요청 결과 대역 (플랫폼 호출 없음, 폐기 횟수 기록)
class _FakeNativeAdHandle extends NativeAdHandle {
  _FakeNativeAdHandle({required this.loadCompleter, required super.requestedAt})
    : super(
        nativeAd: NativeAd(
          adUnitId: 'test',
          factoryId: 'test',
          listener: NativeAdListener(),
          request: const AdRequest(),
        ),
        isLoadedFuture: loadCompleter.future,
      );

  final Completer<bool> loadCompleter;
  int disposeCount = 0;

  @override
  void dispose() {
    disposeCount++;
    super.dispose();
  }
}

/// 홈 피드 광고 칸별 보관: 칸마다 1개, 빌려 그리고 반납, 지난 칸·실패·오래된 광고 정리, 피드 교체 재사용
void main() {
  // 광고 폐기 시 플러그인 채널 객체 생성 (호출 없음)
  TestWidgetsFlutterBinding.ensureInitialized();
  late DateTime currentTime;
  late List<_FakeNativeAdHandle> requestedHandles;

  NativeAdHandle requestFakeAd() {
    final handle = _FakeNativeAdHandle(loadCompleter: Completer<bool>(), requestedAt: currentTime);
    requestedHandles.add(handle);
    return handle;
  }

  HomeFeedNativeAdPreloader buildPreloader() => HomeFeedNativeAdPreloader(now: () => currentTime);

  setUp(() {
    currentTime = DateTime(2026, 11, 4, 12);
    requestedHandles = [];
  });

  group('NativeAdHandle.isLoaded', () {
    test('로드 성공 직후 다른 구독보다 먼저 true (첫 빌드부터 광고 표시)', () async {
      final handle = requestFakeAd() as _FakeNativeAdHandle;
      bool? isLoadedSeenBySubscriber;
      handle.isLoadedFuture.then((_) => isLoadedSeenBySubscriber = handle.isLoaded);
      expect(handle.isLoaded, isFalse);

      handle.loadCompleter.complete(true);
      await Future<void>.delayed(Duration.zero);

      expect(handle.isLoaded, isTrue);
      expect(isLoadedSeenBySubscriber, isTrue);
    });

    test('로드 실패·폐기 > false', () async {
      final failedHandle = requestFakeAd() as _FakeNativeAdHandle;
      failedHandle.loadCompleter.complete(false);
      final disposedHandle = requestFakeAd() as _FakeNativeAdHandle;
      disposedHandle.loadCompleter.complete(true);
      await Future<void>.delayed(Duration.zero);
      disposedHandle.dispose();

      expect(failedHandle.isLoaded, isFalse);
      expect(disposedHandle.isLoaded, isFalse);
    });
  });

  test('preload: 같은 칸은 1번만 요청, 다른 칸은 따로 요청', () {
    final preloader = buildPreloader();

    preloader.preload(5, requestFakeAd);
    preloader.preload(5, requestFakeAd);
    preloader.preload(17, requestFakeAd);

    expect(requestedHandles.length, 2);
  });

  test('빌려 그리고 반납해도 폐기 안 함 > 다시 빌리면 같은 광고 (재요청 없음)', () {
    final preloader = buildPreloader();
    preloader.preload(5, requestFakeAd);

    final firstBorrowedAd = preloader.borrowAd(5, requestFakeAd)!;
    preloader.returnAd(firstBorrowedAd);
    final secondBorrowedAd = preloader.borrowAd(5, requestFakeAd);

    expect(secondBorrowedAd, same(firstBorrowedAd));
    expect(requestedHandles.single.disposeCount, 0);
  });

  test('빌린 중인 광고는 다른 위젯에 또 빌려주지 않음 (AdWidget 중복 방지)', () {
    final preloader = buildPreloader();

    expect(preloader.borrowAd(5, requestFakeAd), isNotNull);
    expect(preloader.borrowAd(5, requestFakeAd), isNull);
  });

  test('보관 광고 없으면 빌릴 때 요청, 광고 ID 없음(null) > null', () {
    final preloader = buildPreloader();

    expect(preloader.borrowAd(5, requestFakeAd), same(requestedHandles.single));
    expect(preloader.borrowAd(17, () => null), isNull);
  });

  test('지난 칸 보관 범위: 12페이지까지 유지, 넘으면 폐기', () {
    final preloader = buildPreloader();
    preloader.preload(5, requestFakeAd);

    preloader.discardAdsFarBehind(5 + HomeFeedNativeAdPreloader.retainedPassedPageCount);
    expect(requestedHandles.single.disposeCount, 0);

    preloader.discardAdsFarBehind(5 + HomeFeedNativeAdPreloader.retainedPassedPageCount + 1);
    expect(requestedHandles.single.disposeCount, 1);
  });

  test('그리는 중에 보관 해제된 광고 > 반납 때 폐기', () {
    final preloader = buildPreloader();
    final borrowedAd = preloader.borrowAd(5, requestFakeAd)!;

    preloader.discardAdsFarBehind(100);
    expect(requestedHandles.single.disposeCount, 0, reason: '그리는 중엔 폐기 미룸');

    preloader.returnAd(borrowedAd);
    expect(requestedHandles.single.disposeCount, 1);
  });

  test('로드 실패 > 보관 비움, 칸당 최대 요청 횟수까지만 재요청', () async {
    final preloader = buildPreloader();

    for (var attempt = 0; attempt < HomeFeedNativeAdPreloader.maximumRequestCountPerAdSlot + 1; attempt++) {
      preloader.preload(5, requestFakeAd);
      if (requestedHandles.last.loadCompleter.isCompleted) continue;
      requestedHandles.last.loadCompleter.complete(false);
      await Future<void>.delayed(Duration.zero);
    }

    expect(requestedHandles.length, HomeFeedNativeAdPreloader.maximumRequestCountPerAdSlot);
    expect(preloader.borrowAd(5, requestFakeAd), isNull, reason: '재요청 다 쓰면 칸 접기');
  });

  test('안 보인 채 오래된 광고 > 폐기 후 새로 요청, 빌려 준 광고는 유지', () {
    final preloader = buildPreloader();
    preloader.preload(5, requestFakeAd);
    final shownAd = preloader.borrowAd(17, requestFakeAd)!;
    preloader.returnAd(shownAd);

    currentTime = currentTime.add(HomeFeedNativeAdPreloader.maximumUnshownAdAge + const Duration(seconds: 1));
    preloader.preload(5, requestFakeAd);
    preloader.preload(17, requestFakeAd);

    expect(requestedHandles.first.disposeCount, 1);
    expect(requestedHandles.length, 3, reason: '5번 칸만 새로 요청');
    expect(preloader.borrowAd(17, requestFakeAd), same(shownAd));
  });

  test('피드 교체: 보인 광고 폐기, 안 보인 광고는 새 광고 칸에 요청 없이 배정', () {
    final preloader = buildPreloader();
    final shownAd = preloader.borrowAd(5, requestFakeAd)!;
    preloader.returnAd(shownAd);
    preloader.preload(17, requestFakeAd);
    final unshownAd = requestedHandles.last;

    preloader.resetForReplacedFeed();
    preloader.preload(5, requestFakeAd);

    expect(requestedHandles.first.disposeCount, 1);
    expect(unshownAd.disposeCount, 0);
    expect(requestedHandles.length, 2, reason: '남은 광고 재사용 > 새 요청 없음');
    expect(preloader.borrowAd(5, requestFakeAd), same(unshownAd));
  });

  test('광고 칸 접힘: 해당 칸 폐기 > 뒤 칸 index 1 당김', () {
    final preloader = buildPreloader();
    preloader.preload(5, requestFakeAd);
    preloader.preload(17, requestFakeAd);
    final laterAd = requestedHandles.last;

    preloader.removeAdSlot(5);

    expect(requestedHandles.first.disposeCount, 1);
    expect(preloader.borrowAd(16, requestFakeAd), same(laterAd));
    expect(requestedHandles.length, 2);
  });

  test('dispose: 보관·빌린 광고 전부 폐기', () {
    final preloader = buildPreloader();
    preloader.preload(5, requestFakeAd);
    preloader.borrowAd(17, requestFakeAd);

    preloader.dispose();

    expect(requestedHandles.every((handle) => handle.disposeCount == 1), isTrue);
  });
}
