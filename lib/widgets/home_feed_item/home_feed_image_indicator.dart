// 홈 피드 카드 사진 위치 점 표시: 현재 사진 노란 점, 나머지 반투명 흰 점
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 홈 피드 사진 점 표시: 사진 수만큼 점, 현재 index 강조
class HomeFeedImageIndicator extends StatelessWidget {
  final int imageCount;
  final int currentImageIndex;

  const HomeFeedImageIndicator({super.key, required this.imageCount, required this.currentImageIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        imageCount,
        (index) => Container(
          width: 6.w,
          height: 6.w,
          margin: EdgeInsets.symmetric(horizontal: 2.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentImageIndex == index ? AppColors.primaryYellow : AppColors.opacity50White,
          ),
        ),
      ),
    );
  }
}
