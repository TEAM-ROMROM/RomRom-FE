import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 온보딩 제목 헤더 위젯
///
/// 메인 제목과 부제목을 표시
class OnboardingTitleHeader extends StatelessWidget {
  /// 메인 제목
  final String title;

  /// 부제목
  final String subtitle;

  const OnboardingTitleHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24.w, right: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          // 메인 제목
          Text(title, style: CustomTextStyles.h1),
          SizedBox(height: 12.h),
          // 부제목
          Text(subtitle, style: CustomTextStyles.p2),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}
