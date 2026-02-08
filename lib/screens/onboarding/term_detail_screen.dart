// lib/screens/onboarding/term_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/term_contents.dart';

class TermDetailScreen extends StatelessWidget {
  final TermContents termsContent;

  const TermDetailScreen({super.key, required this.termsContent});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),

              // 뒤로가기 버튼
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(AppIcons.navigateBefore, size: 24.h, color: AppColors.textColorWhite),
              ),

              SizedBox(height: 36.h),

              // 제목
              Text(termsContent.title, style: CustomTextStyles.h1),

              SizedBox(height: 66.h),

              // 본문 - 스크롤 가능하도록 Expanded + SingleChildScrollView 사용
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    termsContent.content,
                    style: CustomTextStyles.p3.copyWith(
                      color: AppColors.textColorWhite.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
