import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/font_family.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 앱 전체의 테마를 관리하는 클래스
class AppTheme {
  /// 앱의 기본 테마 설정
  static ThemeData get defaultTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      useMaterial3: true,
      fontFamily: FontFamily.pretendard.fontName,
      textTheme: _buildTextTheme(),
      // 필요한 경우 여기에 다른 테마 속성 추가 (버튼, 입력 필드 등)
    );
  }

  /// 앱의 텍스트 테마 정의
  static TextTheme _buildTextTheme() {
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textColor_white,
        height: 1,
        letterSpacing: -0.32.sp,
      ),
      headlineMedium: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textColor_white,
        height: 1,
        letterSpacing: -0.32.sp,
      ),
      bodyMedium: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textColor_black,
        height: 1,
        letterSpacing: -0.32.sp,
      ),
    );
  }
}
