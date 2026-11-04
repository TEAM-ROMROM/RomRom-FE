import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:romrom_fe/models/home_feed_item.dart';
import 'package:romrom_fe/utils/cached_image_precache.dart';
import 'package:romrom_fe/utils/home_feed_ad_slot_schedule.dart';
import 'package:romrom_fe/widgets/home_feed_item_widget.dart';
import 'package:romrom_fe/widgets/home_tab/home_feed_native_ad_request.dart';
import 'package:romrom_fe/widgets/home_tab/home_feed_native_ad_preloader.dart';

// 현재 카드 뒤 첫 이미지를 미리 받을 카드 수
const int upcomingCardImagePrecacheCount = 2;

// 몇 페이지 앞 광고 칸까지 광고 미리 요청 (첫 광고 칸 index 5 > 첫 피드 로드 때 바로 요청)
const int adPreloadLookaheadPageCount = 5;

/// 홈 피드 다음 페이지 준비: 다음 카드 첫 이미지 미리 받기, 앞쪽 광고 칸 광고 미리 요청, 많이 지난 광고 폐기
/// 이미지는 카드와 같은 표시 크기 > 같은 캐시 키 (미리 받은 이미지를 카드가 그대로 사용)
class HomeFeedUpcomingPagePreparer {
  // 광고 칸별 광고 보관 (광고 칸 위젯이 빌려 그림)
  final HomeFeedNativeAdPreloader adPreloader = HomeFeedNativeAdPreloader();

  // 미리 받기 요청한 이미지 URL (같은 이미지 중복 요청 방지)
  final Set<String> _precachedImageUrls = {};

  /// 현재 위치 기준 준비: 이미지 미리 받기 > 지난 광고 정리 > [adPreloadLookaheadPageCount] 안 광고 칸 광고 미리 요청
  void prepare(
    BuildContext context, {
    required List<HomeFeedItem> feedItems,
    required int currentFeedIndex,
    required int currentVirtualIndex,
    required HomeFeedAdSlotSchedule adSlotSchedule,
  }) {
    _precacheUpcomingCardImages(context, feedItems: feedItems, currentFeedIndex: currentFeedIndex);
    adPreloader.discardAdsFarBehind(currentVirtualIndex);
    var adVirtualIndex = adSlotSchedule.nextAdVirtualIndexAfter(currentVirtualIndex);
    while (adVirtualIndex != null && adVirtualIndex - currentVirtualIndex <= adPreloadLookaheadPageCount) {
      adPreloader.preload(adVirtualIndex, () => requestHomeFeedNativeAd(context));
      adVirtualIndex = adSlotSchedule.nextAdVirtualIndexAfter(adVirtualIndex);
    }
  }

  /// 피드 통째 교체: 이미지 요청 기록 초기화, 안 보인 광고는 새 광고 칸에 재사용
  void resetForReplacedFeed() {
    _precachedImageUrls.clear();
    adPreloader.resetForReplacedFeed();
  }

  /// 화면 종료: 받아 둔 광고 폐기
  void dispose() => adPreloader.dispose();

  void _precacheUpcomingCardImages(
    BuildContext context, {
    required List<HomeFeedItem> feedItems,
    required int currentFeedIndex,
  }) {
    final imageDisplaySize = HomeFeedItemWidget.imageDisplaySize(context);
    final lastFeedIndex = min(feedItems.length - 1, currentFeedIndex + upcomingCardImagePrecacheCount);
    for (var feedIndex = currentFeedIndex + 1; feedIndex <= lastFeedIndex; feedIndex++) {
      final imageUrls = feedItems[feedIndex].imageUrls;
      if (imageUrls.isEmpty) continue;
      // 카드도 앞뒤 공백 제거한 URL로 그림
      final imageUrl = imageUrls.first.trim();
      if (imageUrl.isEmpty || !_precachedImageUrls.add(imageUrl)) continue;
      unawaited(
        precacheCachedImage(
          context,
          imageUrl: imageUrl,
          width: imageDisplaySize.width,
          height: imageDisplaySize.height,
        ),
      );
    }
  }
}
