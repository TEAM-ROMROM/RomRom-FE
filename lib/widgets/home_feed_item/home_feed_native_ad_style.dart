// 홈 피드 네이티브 광고 카드 스타일: 물품 카드 토큰 > 네이티브 팩토리 customOptions
// 키 이름은 ios/Runner/FeedNativeAdFactory.swift, android/.../FeedNativeAdFactory.kt 와 함께 바꾼다
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/widgets/home_feed_item/home_feed_card_layout.dart';
import 'package:romrom_fe/widgets/home_feed_item/home_feed_item_summary.dart';
import 'package:romrom_fe/widgets/item_detail_condition_tag.dart';

/// 네이티브 광고 카드 스타일: 물품 카드와 같은 치수·글자·색을 네이티브 뷰에 전달
/// 이름 자리 > 헤드라인, 위치 자리 > 본문, 사용감 태그 자리 > "광고" 배지, 가격 자리 > CTA, 프로필 자리 > 아이콘
class HomeFeedNativeAdStyle {
  const HomeFeedNativeAdStyle._();

  // 광고 표시 배지 문구 (AdMob 정책: 광고임을 알리는 표시 필수)
  static const String adBadgeLabel = '광고';

  // 광고 미디어 하단 <-> 정보 패널 상단 간격 (광고 애셋 위에 글자를 겹치지 않음)
  static double get mediaToInfoPanelGap => 24.h;

  // 헤드라인 최대 줄 수 (AdMob 권장 25자 표시 보장, 물품 이름은 1줄)
  static const int headlineMaxLines = 2;
  // 본문 최대 줄 수 (위치 줄 자리, 긴 본문은 말줄임)
  static const int bodyMaxLines = 2;
  static const int callToActionMaxLines = 1;

  // Pretendard 굵기 > 폰트 파일 (pubspec.yaml fonts.Pretendard 경로와 동일)
  static const Map<int, String> pretendardAssetPathByWeight = {
    400: 'assets/fonts/pretendard/Pretendard-Regular.otf',
    500: 'assets/fonts/pretendard/Pretendard-Medium.otf',
    600: 'assets/fonts/pretendard/Pretendard-SemiBold.otf',
    700: 'assets/fonts/pretendard/Pretendard-Bold.otf',
  };

  /// 현재 화면 배율·글자 배율·상단 안전영역 > 네이티브 팩토리 customOptions (논리 픽셀)
  static Map<String, Object> buildCustomOptions({required TextScaler textScaler, required double topSafeAreaInset}) {
    return {
      'cardBackgroundColorArgb': AppColors.homeFeedCardBackground.toARGB32(),
      'mediaTopCornerRadius': HomeFeedCardLayout.imageTopCornerRadius.x,
      'mediaBottomCornerRadius': HomeFeedCardLayout.imageBottomCornerRadius.x,
      'mediaToInfoPanelGap': mediaToInfoPanelGap,
      'infoPanelBottomInset': HomeFeedCardLayout.infoPanelBottomInset,
      'infoPanelHorizontalPadding': HomeFeedCardLayout.infoPanelHorizontalPadding,
      'titleToMetaGap': HomeFeedCardLayout.titleToMetaGap,
      'metaToTagGap': HomeFeedCardLayout.metaToTagGap,
      'tagToPriceGap': HomeFeedCardLayout.tagToPriceGap,
      'iconSize': HomeFeedCardLayout.profileAvatarSize,
      // AdChoices: 광고 슬롯에서 숨기는 신고 버튼 자리 (상태바 아래, 노치에 가리지 않게)
      'adChoicesTopInset': topSafeAreaInset + HomeFeedCardLayout.topActionsTopOffset,
      'adChoicesTrailingInset': HomeFeedCardLayout.topActionsTrailingInset,
      'headlineText': _buildTextOptions(HomeFeedItemSummary.titleTextStyle, textScaler, headlineMaxLines),
      'bodyText': _buildTextOptions(HomeFeedItemSummary.metaTextStyle, textScaler, bodyMaxLines),
      'callToActionText': _buildTextOptions(HomeFeedItemSummary.priceTextStyle, textScaler, callToActionMaxLines),
      'adBadge': _buildAdBadgeOptions(textScaler),
    };
  }

  /// "광고" 배지: 사용감 태그(ItemDetailConditionTag)와 같은 알약 모양
  static Map<String, Object> _buildAdBadgeOptions(TextScaler textScaler) {
    final EdgeInsets padding = ItemDetailConditionTag.padding;
    final BoxConstraints constraints = ItemDetailConditionTag.constraints;
    return {
      'label': adBadgeLabel,
      'text': _buildTextOptions(ItemDetailConditionTag.textStyle, textScaler, 1),
      'backgroundColorArgb': ItemDetailConditionTag.backgroundColor.toARGB32(),
      'horizontalPadding': padding.left,
      'verticalPadding': padding.top,
      'minWidth': constraints.minWidth,
      'minHeight': constraints.minHeight,
      'cornerRadius': ItemDetailConditionTag.borderRadius,
    };
  }

  /// TextStyle > 글자 크기(글자 배율 반영), 폰트 파일, 색, 최대 줄 수
  static Map<String, Object> _buildTextOptions(TextStyle style, TextScaler textScaler, int maxLines) {
    final int fontWeightValue = (style.fontWeight ?? FontWeight.w400).value;
    return {
      'fontSize': textScaler.scale(style.fontSize!),
      'fontAssetPath': pretendardAssetPathByWeight[fontWeightValue] ?? pretendardAssetPathByWeight[400]!,
      'colorArgb': (style.color ?? AppColors.textColorWhite).toARGB32(),
      'maxLines': maxLines,
    };
  }
}
