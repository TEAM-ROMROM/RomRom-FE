// 홈 탭 피드 빈 상태: '물품이 없습니다.' 안내, 새로고침 버튼
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';

/// 홈 탭 빈 피드: 안내 문구, 새로고침 탭은 화면 콜백
class HomeTabEmptyFeedView extends StatelessWidget {
  final VoidCallback onRefreshTap;

  const HomeTabEmptyFeedView({super.key, required this.onRefreshTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('물품이 없습니다.', style: CustomTextStyles.h3),
          const SizedBox(height: 16),
          AppPressable(
            onTap: onRefreshTap,
            scaleDown: AppPressable.scaleButton,
            enableRipple: false,
            child: Material(
              color: AppColors.primaryYellow,
              borderRadius: BorderRadius.circular(4.r),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text('새로고침', style: CustomTextStyles.p2.copyWith(color: AppColors.textColorBlack)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
