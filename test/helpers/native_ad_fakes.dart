import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 테스트용 네이티브 광고 (load 호출 없음 > 플랫폼 요청 없음, 홈 피드·목록 광고 테스트 공통)
NativeAd buildTestNativeAd() =>
    NativeAd(adUnitId: 'test', factoryId: 'test', listener: NativeAdListener(), request: const AdRequest());
