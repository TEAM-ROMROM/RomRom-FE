// 홈 카드 덱 드롭존: 흐린 유리 영역(그림자 강도 반영) + 안내 아이콘 + 안내 문구 (카드 당김 중에만 표시)
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/home_tab_card_hand/home_tab_card_drop_guide_icon.dart';

class HomeTabCardDropZone extends StatelessWidget {
  // 드롭 판정용 전역 좌표 키 (흰색 드롭존 영역에 부착)
  final GlobalKey dropTargetKey;

  // 0~1, 드롭존 그림자 강도
  final double dropShadowStrength;
  final Animation<double> guideIconAnimation;

  const HomeTabCardDropZone({
    super.key,
    required this.dropTargetKey,
    required this.dropShadowStrength,
    required this.guideIconAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 136.w),
          child: Container(
            key: dropTargetKey,
            width: 122.w,
            height: 189.h,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardDropZoneShadow.withValues(alpha: 0.8 * dropShadowStrength),
                  blurRadius: 30 * (0.5 + 0.5 * dropShadowStrength),
                  spreadRadius: 2 * dropShadowStrength,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BackdropFilter(filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), child: const SizedBox.expand()),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.cardDropZoneBorder, width: 2.w),
                      borderRadius: BorderRadius.circular(8.r),
                      color: AppColors.cardDropZoneBackground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        HomeTabCardDropGuideIcon(offsetAnimation: guideIconAnimation),
        Text("위로 드래그하여\n교환 방식 선택하기", textAlign: TextAlign.center, style: CustomTextStyles.p2.copyWith(height: 1.4)),
      ],
    );
  }
}
