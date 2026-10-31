// 알림함 헤더 오른쪽 버튼: 전체 삭제, 알림 설정
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';

/// 알림함 헤더 버튼: 휴지통(전체 삭제)·톱니(설정) 아이콘, 탭 동작은 화면 콜백
class NotificationHeaderActions extends StatelessWidget {
  final VoidCallback onDeleteAllTap;
  final VoidCallback onSettingsTap;

  const NotificationHeaderActions({super.key, required this.onDeleteAllTap, required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: EdgeInsets.only(right: 8.w), // 기본 16 + 8 = 24px 우측 패딩
          child: AppPressable(
            onTap: onDeleteAllTap,
            scaleDown: AppPressable.scaleIcon,
            enableRipple: false,
            child: Icon(AppIcons.trash, size: 30.sp, color: AppColors.textColorWhite, semanticLabel: '알림 전체 삭제'),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: 8.w), // 기본 16 + 8 = 24px 우측 패딩
          child: AppPressable(
            onTap: onSettingsTap,
            scaleDown: AppPressable.scaleIcon,
            enableRipple: false,
            child: Icon(AppIcons.setting, size: 30.sp, color: AppColors.textColorWhite, semanticLabel: '알림 설정'),
          ),
        ),
      ],
    );
  }
}
