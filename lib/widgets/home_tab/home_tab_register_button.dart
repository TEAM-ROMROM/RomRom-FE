// 홈 탭 내 물품 없음(블러) 상태 하단 '등록하기' 버튼
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';

/// 홈 탭 등록 버튼: 노란 알약 모양, 탭 동작은 화면 콜백
class HomeTabRegisterButton extends StatelessWidget {
  final VoidCallback onTap;

  const HomeTabRegisterButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppPressable(
        onTap: onTap,
        scaleDown: AppPressable.scaleButton,
        enableRipple: false,
        child: Container(
          width: 123.w,
          height: 48.h,
          decoration: BoxDecoration(
            color: AppColors.primaryYellow,
            borderRadius: BorderRadius.circular(100),
            boxShadow: const [BoxShadow(color: AppColors.opacity20Black, blurRadius: 4, offset: Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 24.sp, color: AppColors.primaryBlack),
              SizedBox(width: 4.w),
              Text(
                '등록하기',
                style: CustomTextStyles.h3.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryBlack),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
