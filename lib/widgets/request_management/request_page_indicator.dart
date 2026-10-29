// 요청 관리 물품 카드 캐러셀의 페이지 인디케이터 (점 표시)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';

class RequestPageIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;

  const RequestPageIndicator({super.key, required this.itemCount, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 37.h, 0, 32.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          itemCount,
          (index) => Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            width: 8.w,
            height: 8.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: currentIndex == index ? AppColors.primaryYellow : AppColors.opacity30White,
            ),
          ),
        ),
      ),
    );
  }
}
