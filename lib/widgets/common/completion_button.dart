import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class CompletionButton extends StatelessWidget {
  final bool isEnabled; // 버튼 활성화
  final VoidCallback? enabledOnPressed; // 활성화 상태일 때 눌렀을 때 실행 함수
  final VoidCallback? disabledOnPressed; // 비활성화 상태일 때 눌렀을 때 실행 함수
  final String buttonText; // 버튼 중앙 문구

  // 색 정의
  final Color? enabledBackgroundColor; // 활성화 배경 색
  final Color? disabledBackgroundColor; // 비활성화 배경 색
  final Color? enabledTextColor; // 활성화 문구 색
  final Color? disabledTextColor; // 비활성화 문구 색

  const CompletionButton({
    super.key,
    required this.isEnabled,
    this.enabledOnPressed,
    this.disabledOnPressed,
    required this.buttonText,
    this.enabledBackgroundColor,
    this.disabledBackgroundColor,
    this.enabledTextColor,
    this.disabledTextColor,
  });

  @override
  Widget build(BuildContext context) {
    // 버튼 배경 색 결정
    final Color backgroundColor = isEnabled
        ? enabledBackgroundColor ?? AppColors.primaryYellow
        : disabledBackgroundColor ??
        AppColors.primaryYellow.withValues(alpha: 0.7);

    // 버튼 문구 색 결정
    final Color textColor = isEnabled
        ? enabledTextColor ?? AppColors.textColorBlack
        : disabledTextColor ?? AppColors.textColorBlack.withValues(alpha: 0.7);

    // 버튼 문구  결정
    final TextStyle buttonTextStyle = CustomTextStyles.p1.copyWith(
      color: textColor,
    );

    return Center(
      child: SizedBox(
        width: double.infinity, // 전체 너비 사용
        child: TextButton(
          onPressed: isEnabled
              ? enabledOnPressed
              : disabledOnPressed, // 활성화와 비활성화 일 때 onPressed 별로 처리
          style: TextButton.styleFrom(
              backgroundColor: backgroundColor,
              padding: EdgeInsets.symmetric(vertical: 20.0.h),
              minimumSize: Size(316.w, 0)), // 최소 너비 설정, 높이 자동
          child: Text(
            buttonText,
            style: buttonTextStyle,
            textAlign: TextAlign.center, // 중앙 정렬
            softWrap: false, // 줄 바꿈 방지
          ),
        ),
      ),
    );
  }
}
