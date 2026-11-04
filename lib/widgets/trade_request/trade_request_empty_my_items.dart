import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/custom_floating_button.dart';

/// 요청하기 빈 상태: 교환에 쓸 내 물품 없음 안내 + 돌아가기
class TradeRequestEmptyMyItems extends StatelessWidget {
  final VoidCallback onBackPressed;

  const TradeRequestEmptyMyItems({super.key, required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64.sp, color: AppColors.opacity50White),
            SizedBox(height: 16.h),
            Text('등록된 물품이 없습니다', style: CustomTextStyles.h2.copyWith(color: AppColors.opacity80White)),
            SizedBox(height: 8.h),
            Text(
              '교환 요청을 하려면 먼저\n물품을 등록해주세요.',
              style: CustomTextStyles.p1.copyWith(color: AppColors.opacity50White, height: 1.2),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            CustomFloatingButton(
              isEnabled: true,
              enabledOnPressed: onBackPressed,
              buttonText: '돌아가기',
              buttonWidth: 120,
              buttonHeight: 44,
            ),
          ],
        ),
      ),
    );
  }
}
