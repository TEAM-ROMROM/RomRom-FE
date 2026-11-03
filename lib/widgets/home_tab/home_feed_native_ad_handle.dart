import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:romrom_fe/services/ad_mob_service.dart';
import 'package:romrom_fe/widgets/home_feed_item/home_feed_native_ad_style.dart';

/// 홈 피드 네이티브 광고 1개: 로드 결과(성공 true, 실패 false), 요청 시각
/// 가져간 쪽(광고 칸·미리 받기)이 표시·폐기 책임, 실패한 광고는 자동 폐기
class HomeFeedNativeAdHandle {
  HomeFeedNativeAdHandle({required this.nativeAd, required this.isLoadedFuture, required this.requestedAt});

  final NativeAd nativeAd;
  final Future<bool> isLoadedFuture;
  final DateTime requestedAt;
  bool _isDisposed = false;

  /// 광고 폐기 (여러 번 호출해도 1회)
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    nativeAd.dispose();
  }
}

// 네이티브 팩토리 ID (ios/Runner/AppDelegate.swift, android MainActivity.kt 등록 이름과 함께 바꿈)
const String homeFeedNativeAdFactoryId = 'feedNativeAd';

/// 홈 피드 광고 1개 요청: 광고 ID 없음 > null, 있으면 로드 시작한 광고 (글자 배율·상단 안전영역은 [context] 기준)
HomeFeedNativeAdHandle? requestHomeFeedNativeAd(BuildContext context) {
  final adUnitId = AdMobService.nativeAdUnitId;
  if (adUnitId == null) {
    debugPrint('[AdMob] 네이티브 광고 ID 없음 (프로덕션 .env 미설정)');
    return null;
  }

  final loadCompleter = Completer<bool>();
  final nativeAd = NativeAd(
    adUnitId: adUnitId,
    factoryId: homeFeedNativeAdFactoryId,
    customOptions: HomeFeedNativeAdStyle.buildCustomOptions(
      textScaler: MediaQuery.textScalerOf(context),
      topSafeAreaInset: MediaQuery.paddingOf(context).top,
    ),
    listener: NativeAdListener(
      onAdLoaded: (_) {
        debugPrint('[AdMob] 네이티브 광고 로드 성공');
        if (!loadCompleter.isCompleted) loadCompleter.complete(true);
      },
      onAdFailedToLoad: (_, error) {
        debugPrint('[AdMob] 네이티브 광고 로드 실패: $error');
        if (!loadCompleter.isCompleted) loadCompleter.complete(false);
      },
      onAdOpened: (_) => debugPrint('[AdMob] 네이티브 광고 열림'),
      onAdClosed: (_) => debugPrint('[AdMob] 네이티브 광고 닫힘'),
    ),
    request: const AdRequest(),
  );
  final handle = HomeFeedNativeAdHandle(
    nativeAd: nativeAd,
    isLoadedFuture: loadCompleter.future,
    requestedAt: DateTime.now(),
  );
  // 실패한 광고 즉시 폐기 (누가 들고 있든 공통)
  unawaited(
    loadCompleter.future.then((isLoaded) {
      if (!isLoaded) handle.dispose();
    }),
  );
  nativeAd.load();
  return handle;
}
