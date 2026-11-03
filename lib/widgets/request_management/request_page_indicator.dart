// 물품 카드 캐러셀 페이지 인디케이터 (점 표시, 카드가 많으면 '현재 / 전체' 숫자)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class RequestPageIndicator extends StatelessWidget {
  // 점으로 표시할 최대 카드 수 (초과 시 한 줄 넘침 방지 > 숫자 표시)
  static const int maximumDotCount = 10;

  final int itemCount;
  final int currentIndex;

  // 바깥 여백 (미지정 > 요청관리 탭 기본 여백)
  final EdgeInsetsGeometry? padding;

  const RequestPageIndicator({super.key, required this.itemCount, required this.currentIndex, this.padding});

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: padding ?? EdgeInsets.fromLTRB(0, 37.h, 0, 32.h),
      child: itemCount > maximumDotCount ? _buildPageCounter() : _buildDots(),
    );
  }

  /// 카드 수 이하 점 목록 (현재 카드 강조)
  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        itemCount,
        (index) => Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentIndex == index ? AppColors.primaryYellow : AppColors.opacity30White,
          ),
        ),
      ),
    );
  }

  /// '현재 / 전체' 숫자 (예: 3 / 25)
  Widget _buildPageCounter() {
    return Center(
      child: Text(
        '${currentIndex + 1} / $itemCount',
        style: CustomTextStyles.p3.copyWith(fontWeight: FontWeight.w500, color: AppColors.opacity60White),
      ),
    );
  }
}
