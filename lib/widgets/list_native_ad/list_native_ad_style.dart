// 목록 네이티브 광고 칸 스타일: 앱 토큰 > 네이티브 팩토리 customOptions, 칸 높이 계산
// 키 이름은 ios/Runner/ListNativeAdFactory.swift, android/.../ListNativeAdFactory.kt 와 함께 바꾼다
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/home_feed_item/home_feed_native_ad_style.dart';

/// 목록 광고 칸: [아이콘] [광고 배지 + 헤드라인 / 본문] [CTA] 한 줄, 고정 px (모달처럼 iPad에서 과하게 커지지 않음)
/// 바탕은 목록 행과 다른 색, "광고" 배지 필수 (AdMob 정책: 콘텐츠로 위장 금지)
class ListNativeAdStyle {
  const ListNativeAdStyle._();

  // 광고 표시 배지 문구 (AdMob 정책: 광고임을 알리는 표시 필수)
  static const String adBadgeLabel = HomeFeedNativeAdStyle.adBadgeLabel;

  // 칸 안쪽 여백·모서리
  static const double innerHorizontalPadding = 12;
  static const double innerVerticalPadding = 12;
  static const double cornerRadius = 12;
  // 목록 행과 칸 사이 위아래 간격 (행 탭 영역·메뉴 버튼과 거리 확보)
  static const double outerVerticalMargin = 8;

  static const double iconSize = 44;
  static const double iconCornerRadius = 8;
  static const double iconToTextGap = 12;
  static const double textToCallToActionGap = 12;
  static const double badgeToHeadlineGap = 6;
  static const double headlineToBodyGap = 4;

  static const double badgeHorizontalPadding = 6;
  static const double badgeVerticalPadding = 3;
  static const double badgeCornerRadius = 4;

  static const double callToActionHeight = 32;
  static const double callToActionHorizontalPadding = 12;
  static const double callToActionMaximumWidth = 96;

  // 네이티브 라벨 한 줄 높이 / 글자 크기 (Pretendard 행간 여유 포함)
  static const double nativeLineHeightRatio = 1.3;

  static TextStyle get headlineTextStyle => CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get bodyTextStyle =>
      CustomTextStyles.p3.copyWith(fontWeight: FontWeight.w500, color: AppColors.opacity60White);
  static TextStyle get badgeTextStyle =>
      CustomTextStyles.p4.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryBlack);
  static TextStyle get callToActionTextStyle =>
      CustomTextStyles.p3.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryBlack);

  /// 광고 칸 높이 (바깥 간격 제외): 위아래 여백 + max(아이콘, CTA, 글자 2줄)
  static double cellHeight(TextScaler textScaler) {
    double lineHeight(TextStyle style) => textScaler.scale(style.fontSize!) * nativeLineHeightRatio;
    final badgeHeight = lineHeight(badgeTextStyle) + badgeVerticalPadding * 2;
    final firstLineHeight = max(badgeHeight, lineHeight(headlineTextStyle));
    final textColumnHeight = firstLineHeight + headlineToBodyGap + lineHeight(bodyTextStyle);
    return innerVerticalPadding * 2 + [iconSize, callToActionHeight, textColumnHeight].reduce(max);
  }

  /// 글자 배율 > 네이티브 팩토리 customOptions (논리 픽셀)
  static Map<String, Object> buildCustomOptions({required TextScaler textScaler}) {
    return {
      'backgroundColorArgb': AppColors.listNativeAdBackground.toARGB32(),
      'cornerRadius': cornerRadius,
      'innerHorizontalPadding': innerHorizontalPadding,
      'innerVerticalPadding': innerVerticalPadding,
      'iconSize': iconSize,
      'iconCornerRadius': iconCornerRadius,
      'iconToTextGap': iconToTextGap,
      'textToCallToActionGap': textToCallToActionGap,
      'badgeToHeadlineGap': badgeToHeadlineGap,
      'headlineToBodyGap': headlineToBodyGap,
      'headlineText': HomeFeedNativeAdStyle.buildTextOptions(headlineTextStyle, textScaler, 1),
      'bodyText': HomeFeedNativeAdStyle.buildTextOptions(bodyTextStyle, textScaler, 1),
      'adBadge': {
        'label': adBadgeLabel,
        'text': HomeFeedNativeAdStyle.buildTextOptions(badgeTextStyle, textScaler, 1),
        'backgroundColorArgb': AppColors.conditionTagBackground.toARGB32(),
        'horizontalPadding': badgeHorizontalPadding,
        'verticalPadding': badgeVerticalPadding,
        'cornerRadius': badgeCornerRadius,
      },
      'callToAction': {
        'text': HomeFeedNativeAdStyle.buildTextOptions(callToActionTextStyle, textScaler, 1),
        'backgroundColorArgb': AppColors.primaryYellow.toARGB32(),
        'height': callToActionHeight,
        'horizontalPadding': callToActionHorizontalPadding,
        'maximumWidth': callToActionMaximumWidth,
      },
    };
  }
}
