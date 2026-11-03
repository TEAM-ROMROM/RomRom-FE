import 'package:romrom_fe/widgets/home_tab/home_feed_native_ad_handle.dart';

/// 홈 피드 광고 미리 받기: 다음 광고 칸 도착 전 1개만 요청·보관 > 광고 칸이 가져가 표시 (소유권 이전)
/// 로드 실패는 비우고 다음 기회 재요청, 오래된 광고는 폐기 (AdMob: 로드 후 1시간 안에 표시 권장)
class HomeFeedNativeAdPreloader {
  HomeFeedNativeAdPreloader({DateTime Function()? now}) : _now = now ?? DateTime.now;

  // 미리 받은 광고 최대 보관 시간
  static const Duration maximumPreloadedAdAge = Duration(minutes: 50);

  final DateTime Function() _now;
  HomeFeedNativeAdHandle? _preloadedAd;

  /// 보관 중 광고 없으면 1개 요청 ([requestAd] 결과 null = 광고 ID 없음 > 보관 안 함)
  void preload(HomeFeedNativeAdHandle? Function() requestAd) {
    _discardExpiredAd();
    if (_preloadedAd != null) return;
    final requestedAd = requestAd();
    if (requestedAd == null) return;
    _preloadedAd = requestedAd;
    requestedAd.isLoadedFuture.then((isLoaded) {
      if (!isLoaded && identical(_preloadedAd, requestedAd)) _preloadedAd = null;
    });
  }

  /// 광고 칸이 보관 광고를 가져감 (로드 중이어도 전달, 없으면 null > 광고 칸이 직접 요청)
  HomeFeedNativeAdHandle? takePreloadedAd() {
    _discardExpiredAd();
    final preloadedAd = _preloadedAd;
    _preloadedAd = null;
    return preloadedAd;
  }

  /// 보관 중 광고 폐기 (화면 종료 시)
  void dispose() {
    _preloadedAd?.dispose();
    _preloadedAd = null;
  }

  void _discardExpiredAd() {
    final preloadedAd = _preloadedAd;
    if (preloadedAd == null) return;
    if (_now().difference(preloadedAd.requestedAt) <= maximumPreloadedAdAge) return;
    preloadedAd.dispose();
    _preloadedAd = null;
  }
}
