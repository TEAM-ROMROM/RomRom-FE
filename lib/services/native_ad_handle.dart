import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:romrom_fe/services/ad_sdk_initializer.dart';

/// 네이티브 광고 1개: 로드 결과(성공 true, 실패 false), 동기 로드 완료 여부, 요청 시각
/// 가져간 쪽(광고 칸·미리 받기)이 표시·폐기 책임, 실패한 광고는 자동 폐기
class NativeAdHandle {
  NativeAdHandle({required this.nativeAd, required this.isLoadedFuture, required this.requestedAt}) {
    // 다른 구독보다 먼저 등록 > 로드 완료 알림 시점엔 isLoaded가 이미 true
    isLoadedFuture.then((isLoaded) => _isLoaded = isLoaded);
  }

  final NativeAd nativeAd;
  final Future<bool> isLoadedFuture;
  final DateTime requestedAt;
  bool _isLoaded = false;
  bool _isDisposed = false;

  /// 로드 성공 여부 (동기, 이미 받은 광고를 첫 빌드부터 바로 그리기 위함)
  bool get isLoaded => _isLoaded && !_isDisposed;

  bool get isDisposed => _isDisposed;

  /// 광고 폐기 (여러 번 호출해도 1회)
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    nativeAd.dispose();
  }
}

/// 네이티브 광고 1개 요청: 광고 ID 없음 > null, 있으면 광고 요청 허용 뒤 로드 시작한 광고
/// 동의·SDK 초기화 전이면 허용될 때까지 대기 (요청 금지 확정 > 로드 실패 처리)
NativeAdHandle? requestNativeAd({
  required String? adUnitId,
  required String factoryId,
  required Map<String, Object> customOptions,
  required String logLabel,
  NativeAdOptions? nativeAdOptions,
}) {
  if (adUnitId == null) {
    debugPrint('[AdMob] $logLabel native ad unit id missing (release .env)');
    return null;
  }

  final loadCompleter = Completer<bool>();
  final nativeAd = NativeAd(
    adUnitId: adUnitId,
    factoryId: factoryId,
    customOptions: customOptions,
    nativeAdOptions: nativeAdOptions,
    listener: NativeAdListener(
      onAdLoaded: (_) {
        debugPrint('[AdMob] $logLabel native ad loaded');
        if (!loadCompleter.isCompleted) loadCompleter.complete(true);
      },
      onAdFailedToLoad: (_, error) {
        debugPrint('[AdMob] $logLabel native ad failed : $error');
        if (!loadCompleter.isCompleted) loadCompleter.complete(false);
      },
    ),
    request: const AdRequest(),
  );
  final handle = NativeAdHandle(nativeAd: nativeAd, isLoadedFuture: loadCompleter.future, requestedAt: DateTime.now());
  // 실패한 광고 즉시 폐기 (누가 들고 있든 공통)
  unawaited(
    loadCompleter.future.then((isLoaded) {
      if (!isLoaded) handle.dispose();
    }),
  );
  unawaited(
    AdSdkInitializer.whenAdRequestAllowed.then((isAdRequestAllowed) {
      // 요청 금지 확정·기다리는 동안 폐기 > 요청 생략
      if (!isAdRequestAllowed || handle.isDisposed) {
        if (!loadCompleter.isCompleted) loadCompleter.complete(false);
        return;
      }
      nativeAd.load();
    }),
  );
  return handle;
}
