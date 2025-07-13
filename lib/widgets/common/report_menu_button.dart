import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 신고하기 메뉴 버튼 (우측 상단 점 3개 아이콘)
class ReportMenuButton extends StatelessWidget {
  final VoidCallback? onReportPressed;

  const ReportMenuButton({super.key, this.onReportPressed});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ReportMenuOption>(
      offset: Offset(0, 12.h),
      position: PopupMenuPosition.under,
      color: AppColors.secondaryBlack,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.r),
      ),
      constraints: BoxConstraints(
        minWidth: 146.w,
        maxWidth: 146.w,
        maxHeight: 46.h,
      ),
      padding: EdgeInsets.zero,
      menuPadding: EdgeInsets.zero,
      icon: Icon(
        AppIcons.dotsVertical,
        size: 30.sp,
        color: AppColors.textColorWhite,
      ),
      itemBuilder: (context) => [
        PopupMenuItem<_ReportMenuOption>(
          value: _ReportMenuOption.report,
          padding: EdgeInsets.only(left: 16.w),
          height: 46.h,
          child: Text(
            '신고하기',
            style: CustomTextStyles.p2.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
      onSelected: (_ReportMenuOption option) {
        if (option == _ReportMenuOption.report) {
          if (onReportPressed != null) onReportPressed!();
        }
      },
    );
  }
}

// 내부용 enum (외부 노출 불필요)
enum _ReportMenuOption { report } 