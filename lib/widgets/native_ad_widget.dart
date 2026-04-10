import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/services/ad_mob_service.dart';

/// 홈 피드용 네이티브 광고 위젯
/// PageView 한 페이지를 채우는 전체화면 크기로 표시됨
class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  static const String _factoryId = 'feedNativeAd';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adUnitId = AdMobService.nativeAdUnitId;
    if (adUnitId == null) {
      debugPrint('[AdMob] 네이티브 광고 ID 없음 (프로덕션 .env 미설정)');
      return;
    }

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: _factoryId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('[AdMob] 네이티브 광고 로드 성공');
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdMob] 네이티브 광고 로드 실패: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _nativeAd = null;
            });
          }
        },
        onAdOpened: (_) => debugPrint('[AdMob] 네이티브 광고 열림'),
        onAdClosed: (_) => debugPrint('[AdMob] 네이티브 광고 닫힘'),
      ),
      request: const AdRequest(),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) {
      return const ColoredBox(
        color: AppColors.primaryBlack,
        child: Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)),
      );
    }

    return Center(
      child: ColoredBox(
        color: AppColors.primaryBlack,
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}
