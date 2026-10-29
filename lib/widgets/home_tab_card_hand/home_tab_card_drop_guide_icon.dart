// 홈 카드 덱 드롭 안내 아이콘: 위아래 반복 이동 (오프셋 애니메이션 구독, 카드 당김 중에만 재생)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';

class HomeTabCardDropGuideIcon extends AnimatedWidget {
  const HomeTabCardDropGuideIcon({super.key, required Animation<double> offsetAnimation})
    : super(listenable: offsetAnimation);

  // 아이콘 이동량 (0 ~ 10px)
  Animation<double> get offsetAnimation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 32.0.h - offsetAnimation.value, bottom: 20.h + offsetAnimation.value),
      child: const Icon(AppIcons.cardDrag, color: AppColors.primaryYellow),
    );
  }
}
