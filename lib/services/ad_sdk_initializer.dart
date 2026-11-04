import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 광고 SDK 준비: UMP 동의 정보 갱신, 필요할 때만 동의 폼, 광고 요청 가능 시 MobileAds 초기화
/// 지난 세션 동의로 요청 가능 > 동의 갱신과 병렬로 즉시 초기화 (Google UMP 권장 순서)
class AdSdkInitializer {
  const AdSdkInitializer._();

  static final Completer<bool> _adRequestAllowedCompleter = Completer<bool>();
  static bool _hasStarted = false;
  static bool _hasStartedMobileAdsInitialization = false;

  /// 광고 요청 가능 여부 (true: 동의 확인 + SDK 초기화 완료, false: 동의 없어 요청 금지)
  /// 광고 요청은 반드시 이 결과 뒤 (동의 전 요청 금지, AdMob 정책)
  static Future<bool> get whenAdRequestAllowed => _adRequestAllowedCompleter.future;

  /// 앱 시작 직후 1회 호출 (기다리지 않음, env 미사용: 앱 ID는 Info.plist·AndroidManifest)
  static void start() {
    if (_hasStarted) return;
    _hasStarted = true;
    // 지난 세션 동의 > 즉시 초기화 (동의 갱신 응답 대기 없음)
    unawaited(_initializeMobileAdsIfAllowed(isFinalConsentDecision: false));
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        debugPrint('[UMP] consent info updated');
        // 동의 필요할 때만 폼 로드·표시 (불필요하면 바로 닫힘 콜백)
        ConsentForm.loadAndShowConsentFormIfRequired((FormError? formError) {
          if (formError != null) debugPrint('[UMP] consent form failed : ${formError.message}');
          unawaited(_initializeMobileAdsIfAllowed(isFinalConsentDecision: true));
        });
      },
      (FormError error) {
        debugPrint('[UMP] consent info update failed : ${error.message}');
        unawaited(_initializeMobileAdsIfAllowed(isFinalConsentDecision: true));
      },
    );
  }

  /// 요청 가능 확인 > MobileAds 초기화 1회 > 광고 요청 허용 (최종 판단에서도 불가면 요청 금지 확정)
  static Future<void> _initializeMobileAdsIfAllowed({required bool isFinalConsentDecision}) async {
    final canRequestAds = await ConsentInformation.instance.canRequestAds();
    if (!canRequestAds) {
      if (isFinalConsentDecision && !_adRequestAllowedCompleter.isCompleted) _adRequestAllowedCompleter.complete(false);
      return;
    }
    if (_hasStartedMobileAdsInitialization) return;
    _hasStartedMobileAdsInitialization = true;
    try {
      await MobileAds.instance.initialize();
      debugPrint('[AdMob] mobile ads initialized');
    } catch (error) {
      // 초기화 실패해도 광고 요청은 SDK가 자체 초기화 후 처리
      debugPrint('[AdMob] mobile ads initialize failed : $error');
    }
    if (!_adRequestAllowedCompleter.isCompleted) _adRequestAllowedCompleter.complete(true);
  }
}
