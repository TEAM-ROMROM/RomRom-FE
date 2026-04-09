import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:romrom_fe/debug/debug_config.dart';

class AdMobService {
  // 앱 개발 시 테스트 광고 ID
  static String? get bannerAdUnitId {
    if (DebugConfig.isTestBuild) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111'; // 테스트 배너 광고 ID (Android)
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716'; // 테스트 배너 광고 ID (iOS)
      }
    }
    return null; // 실제 광고 ID는 .env에서 관리
  }

  // 전면 광고 ID (실제 광고 ID는 .env에서 관리)
  static String? get interstitialAdUnitId {
    if (DebugConfig.isTestBuild) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/1033173712'; // 테스트 전면 광고 ID (Android)
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/4411468910'; // 테스트 전면 광고 ID (iOS)
      }
    }
    return null; // 실제 광고 ID는 .env에서 관리
  }

  // 보상형 광고 ID (실제 광고 ID는 .env에서 관리)
  static String? get rewardedAdUnitId {
    if (DebugConfig.isTestBuild) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/5224354917'; // 테스트 보상형 광고 ID (Android)
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/1712485313'; // 테스트 보상형 광고 ID (iOS)
      }
    }
    return null; // 실제 광고 ID는 .env에서 관리
  }

  // 네이티브 광고 ID (실제 광고 ID는 .env에서 관리)
  static String? get nativeAdUnitId {
    if (DebugConfig.isTestBuild) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/2247696110'; // 테스트 네이티브 광고 ID (Android)
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/3986624511'; // 테스트 네이티브 광고 ID (iOS)
      }
    }
    return dotenv.get('NATIVE_ADMOB_APP_ID'); // 실제 광고 ID는 .env에서 관리
  }

  // 광고 이벤트 리스너 (공통)
  static final BannerAdListener bannerAdListener = BannerAdListener(
    onAdLoaded: (ad) => debugPrint('[AdMob] 배너 광고 로드 성공: ${ad.adUnitId}'),
    onAdFailedToLoad: (ad, error) {
      debugPrint('[AdMob] 배너 광고 로드 실패: ${ad.adUnitId}, 오류: $error');
      ad.dispose();
    },
    onAdOpened: (ad) => debugPrint('[AdMob] 배너 광고 열림: ${ad.adUnitId}'),
    onAdClosed: (ad) => debugPrint('[AdMob] 배너 광고 닫힘: ${ad.adUnitId}'),
  );
}
