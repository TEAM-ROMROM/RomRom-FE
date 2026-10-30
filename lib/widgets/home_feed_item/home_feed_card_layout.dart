// 홈 피드 카드 공통 치수: 물품 카드(HomeFeedItemWidget)·네이티브 광고 카드(HomeFeedNativeAdStyle) 단일 원본
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 홈 피드 카드 치수: 카드 모서리, 하단 정보 패널 위치·간격, 프로필 크기, 우측 상단 버튼 위치
/// 값은 ScreenUtil 배율 적용 후 논리 픽셀 (네이티브 광고 뷰에 그대로 전달)
class HomeFeedCardLayout {
  const HomeFeedCardLayout._();

  // 카드 이미지 모서리 (위 4, 아래 20)
  static Radius get imageTopCornerRadius => Radius.circular(4.r);
  static Radius get imageBottomCornerRadius => Radius.circular(20.r);

  // 하단 정보 패널: 카드 아래에서 띄우는 거리(카드 덱 위), 좌우 여백
  static double get infoPanelBottomInset => 110.h;
  static double get infoPanelHorizontalPadding => 24.w;

  // 정보 패널 세로 간격: 이름 > 위치 > 태그 > 가격
  static double get titleToMetaGap => 8.h;
  static double get metaToTagGap => 12.h;
  static double get tagToPriceGap => 10.h;

  // 작성자 프로필 지름 (iPad 확대 방지 고정값)
  static const double profileAvatarSize = 50;

  // 우측 상단 버튼(알림·신고) 위치: 상태바 아래 거리, 오른쪽 여백
  static double get topActionsTopOffset => Platform.isAndroid ? 16.h : 8.h;
  static double get topActionsTrailingInset => 16.w;
}
