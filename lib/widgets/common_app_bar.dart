import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  const CommonAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 82.h,
      leadingWidth: 52.w,
      leading: IconButton(
        alignment: Alignment.centerRight,
        icon: Icon(
          AppIcons.navigateBefore,
          size: 24.h,
          color: AppColors.textColorWhite,
        ),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        padding: EdgeInsets.zero,
      ),
      title: Text(
        title,
        style: CustomTextStyles.h2,
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(82.h);
}
