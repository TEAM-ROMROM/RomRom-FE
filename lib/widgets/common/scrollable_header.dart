import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 스크롤에 따라 동적으로 크기가 변하는 헤더 위젯
class ScrollableHeader extends StatelessWidget {
  /// 헤더 제목
  final String title;
  
  /// 헤더 확장 높이 (기본값: 88)
  final double expandedHeight;
  
  /// 헤더 축소 높이 (기본값: 58)
  final double toolbarHeight;
  
  /// 스크롤 여부 또는 스크롤된 상태
  final bool isScrolled;

  const ScrollableHeader({
    super.key,
    required this.title,
    required this.isScrolled,
    this.expandedHeight = 88,
    this.toolbarHeight = 58,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.primaryBlack,
      expandedHeight: expandedHeight.h,
      toolbarHeight: toolbarHeight.h,
      titleSpacing: 0,
      elevation: isScrolled ? 0.5 : 0,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: EdgeInsets.only(top: 16.h, bottom: 24.h),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isScrolled ? 1.0 : 0.0,
          child: Text(
            title,
            style: CustomTextStyles.h3.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      centerTitle: true,
      flexibleSpace: Container(
        color: AppColors.primaryBlack,
        child: FlexibleSpaceBar(
          background: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
            child: Align(
              alignment: Alignment.topLeft,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isScrolled ? 0.0 : 1.0,
                child: Text(
                  title,
                  style: CustomTextStyles.h1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
