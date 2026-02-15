import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';

class CustomFloatingButton extends StatelessWidget {
  final bool isEnabled; // 버튼 활성화
  final VoidCallback? enabledOnPressed; // 활성화 상태일 때 눌렀을 때 실행 함수
  final VoidCallback? disabledOnPressed; // 비활성화 상태일 때 눌렀을 때 실행 함수
  final String buttonText; // 버튼 중앙 문구

  // 색 정의
  final Color? enabledBackgroundColor; // 활성화 배경 색
  final Color? disabledBackgroundColor; // 비활성화 배경 색
  final Color? enabledTextColor; // 활성화 문구 색
  final Color? disabledTextColor; // 비활성화 문구 색

  final double buttonWidth;
  final double buttonHeight;

  const CustomFloatingButton({
    super.key,
    required this.isEnabled,
    this.enabledOnPressed,
    this.disabledOnPressed,
    required this.buttonText,
    this.enabledBackgroundColor,
    this.disabledBackgroundColor,
    this.enabledTextColor,
    this.disabledTextColor,
    this.buttonWidth = 96,
    this.buttonHeight = 32,
  });

  @override
  Widget build(BuildContext context) {
    // 버튼 배경 색 결정
    final Color backgroundColor = isEnabled
        ? enabledBackgroundColor ?? AppColors.primaryYellow
        : disabledBackgroundColor ?? AppColors.primaryYellow.withValues(alpha: 0.3);

    // 버튼 문구 색 결정
    final Color textColor = isEnabled
        ? enabledTextColor ?? AppColors.textColorBlack
        : disabledTextColor ?? AppColors.textColorBlack.withValues(alpha: 0.7);

    // 버튼 문구  결정
    final TextStyle buttonTextStyle = CustomTextStyles.p1.copyWith(color: textColor);

    // 버튼 highlightColor와 splashColor는 backgroundColor를 어둡게 한 색상으로 설정
    final Color highlightColor = darkenBlend(backgroundColor);
    final Color splashColor = highlightColor.withValues(alpha: 0.3);

    return Center(
      child: SizedBox(
        width: buttonWidth.w,
        height: buttonHeight.h,
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10.r),
          child: InkWell(
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            onTap: isEnabled ? enabledOnPressed : disabledOnPressed,
            highlightColor: highlightColor,
            splashColor: splashColor,
            borderRadius: BorderRadius.circular(10.r),
            child: Center(
              child: Text(buttonText, style: buttonTextStyle, textAlign: TextAlign.center, softWrap: false),
            ),
          ),
        ),
      ),
    );
  }
}
