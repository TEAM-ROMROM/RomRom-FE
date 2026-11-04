// 홈 피드 네이티브 광고 요청: 팩토리 ID·스타일 > NativeAdHandle (광고 수명은 HomeFeedNativeAdPreloader)
import 'package:flutter/widgets.dart';
import 'package:romrom_fe/services/ad_mob_service.dart';
import 'package:romrom_fe/services/native_ad_handle.dart';
import 'package:romrom_fe/widgets/home_feed_item/home_feed_native_ad_style.dart';

// 네이티브 팩토리 ID (등록 이름과 같은 값: ios/Runner/AppDelegate.swift, android MainActivity.kt)
const String homeFeedNativeAdFactoryId = 'feedNativeAd';

/// 홈 피드 광고 1개 요청: 광고 ID 없음 > null, 있으면 로드 시작한 광고 (글자 배율·상단 안전영역은 [context] 기준)
NativeAdHandle? requestHomeFeedNativeAd(BuildContext context) {
  return requestNativeAd(
    adUnitId: AdMobService.nativeAdUnitId,
    factoryId: homeFeedNativeAdFactoryId,
    customOptions: HomeFeedNativeAdStyle.buildCustomOptions(
      textScaler: MediaQuery.textScalerOf(context),
      topSafeAreaInset: MediaQuery.paddingOf(context).top,
    ),
    logLabel: 'home feed',
  );
}
