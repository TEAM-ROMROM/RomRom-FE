import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_theme.dart';

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
        maxHeight: 92.h,
      ),
      padding: EdgeInsets.zero,
      menuPadding: EdgeInsets.zero,
      icon: Icon(
        AppIcons.dotsVertical,
        size: 30.sp,
        color: AppColors.textColorWhite,
      ),
      itemBuilder: (context) => [
        // 수정 옵션
        PopupMenuItem<ItemMenuOption>(
          value: ItemMenuOption.edit,
          padding: EdgeInsets.only(left: 12.w),
          height: 46.h,
          child: Text(
            '수정',
            style: CustomTextStyles.p2.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // 구분선
        PopupMenuItem<ItemMenuOption>(
          enabled: false,
          height: 1.h,
          padding: EdgeInsets.zero,
          child: Divider(
            color: AppColors.opacity10White,
            thickness: 1.h,
            height: 1.h,
            indent: 12.w,
            endIndent: 12.w,
          ),
        ),
        // 삭제 옵션
        PopupMenuItem<ItemMenuOption>(
          value: ItemMenuOption.delete,
          padding: EdgeInsets.only(left: 12.w),
          height: 46.h,
          child: Text(
            '삭제',
            style: CustomTextStyles.p2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.itemOptionsMenuDeleteText),
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
