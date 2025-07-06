import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/icons/app_icons.dart';

// 옵션 메뉴 항목 정의
enum ItemMenuOption {
  edit,
  delete,
}

// 아이템 옵션 메뉴 아이콘 버튼
class ItemOptionsMenuButton extends StatelessWidget {
  final VoidCallback? onEditPressed;
  final VoidCallback? onDeletePressed;

  const ItemOptionsMenuButton({
    super.key,
    this.onEditPressed,
    this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ItemMenuOption>(
      offset: Offset(0, 30.h),
      position: PopupMenuPosition.under,
      color: AppColors.secondaryBlack,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.r),
      ),
      constraints: BoxConstraints(
        minWidth: 146.w,
        maxWidth: 146.w,
      ),
      padding: EdgeInsets.zero,
      icon: Icon(
        AppIcons.dotsVertical,
        size: 24.sp,
        color: AppColors.opacity50White,
      ),
      itemBuilder: (context) => [
        // 수정 옵션
        PopupMenuItem<ItemMenuOption>(
          value: ItemMenuOption.edit,
          height: 48.h,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
            child: Text(
              '수정',
              style: TextStyle(
                color: AppColors.textColorWhite,
                fontFamily: 'Pretendard',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
          ),
        ),
        // 구분선
        PopupMenuItem<ItemMenuOption>(
          enabled: false,
          height: 1.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Container(
            width: 122.w,
            height: 1.h,
            color: AppColors.textColorWhite.withValues(alpha: 10),
          ),
        ),
        // 삭제 옵션
        PopupMenuItem<ItemMenuOption>(
          value: ItemMenuOption.delete,
          height: 48.h,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
            child: Text(
              '삭제',
              style: TextStyle(
                color: AppColors.itemOptionsMenuDeleteText,
                fontFamily: 'Pretendard',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
          ),
        ),
      ],
      onSelected: (ItemMenuOption option) {
        switch (option) {
          case ItemMenuOption.edit:
            if (onEditPressed != null) onEditPressed!();
            break;
          case ItemMenuOption.delete:
            if (onDeletePressed != null) onDeletePressed!();
            break;
        }
      },
    );
  }
}
