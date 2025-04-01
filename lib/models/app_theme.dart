import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/font_family.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 앱 전체의 테마를 관리하는 클래스
class AppTheme {
  /// 앱의 기본 테마 설정
  static ThemeData get defaultTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.main_131419, // 앱 전체 기본 배경 색상
      useMaterial3: true,
      fontFamily: FontFamily.pretendard.fontName, // 기본 글씨체 : `Pretendard`
    );
  }

  static CustomTextStyles get textStyles => CustomTextStyles();
}

/// 커스텀 텍스트 스타일 모음 (fimga 디자인 시스템과 동일)
class CustomTextStyles {
  /// h1 : 24px
  static TextStyle h1 = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 24.sp,
    height: 1,
    letterSpacing: 0.sp,
    color: AppColors.textColorWhite,
  );

  /// h3 : 18px
  static TextStyle h3 = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 18.sp,
    height: 1,
    letterSpacing: 0.sp,
    color: AppColors.textColorWhite,
  );

  /// p1 : 16px
  static TextStyle p1 = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 16.sp,
    height: 1,
    letterSpacing: 0.sp,
    color: AppColors.textColorWhite,
  );

  /// p2 : 14px
  static TextStyle p2 = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 14.sp,
    height: 1,
    letterSpacing: 0.sp,
    color: AppColors.textColorWhite,
  );
}
