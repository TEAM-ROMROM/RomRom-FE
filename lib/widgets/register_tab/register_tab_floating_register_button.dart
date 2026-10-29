// 등록 탭 하단 '등록하기' 떠 있는 버튼: 스크롤 중 축소·투명 숨김, 숨김 중 터치 무시
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';

/// 등록 탭 등록 버튼: 숨김 애니메이션, 탭 동작은 화면 콜백
class RegisterTabFloatingRegisterButton extends StatelessWidget {
  // 스크롤 중이면 숨김 (스크롤 멈춘 뒤 0.5초 후 다시 표시는 화면이 판단)
  final bool isHidden;
  final VoidCallback onTap;

  const RegisterTabFloatingRegisterButton({super.key, required this.isHidden, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: isHidden,
      child: AnimatedScale(
        duration: AppMotion.fast,
        scale: isHidden ? 0.0 : 1.0,
        curve: AppMotion.standard,
        child: AnimatedOpacity(
          duration: AppMotion.fast,
          opacity: isHidden ? 0.0 : 1.0,
          child: Center(
            child: AppPressable(
              scaleDown: AppPressable.scaleButton,
              enableRipple: false,
              borderRadius: BorderRadius.circular(100.r),
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(100.r),
                  boxShadow: const [BoxShadow(color: AppColors.opacity20Black, blurRadius: 4, offset: Offset(0, 4))],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.addItemPlus, size: 16.sp, color: AppColors.primaryBlack),
                      SizedBox(width: 8.w),
                      Text(
                        '등록하기',
                        style: CustomTextStyles.h3.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColorBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
