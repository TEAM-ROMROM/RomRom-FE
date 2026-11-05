import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/services/notification_permission_service.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';

/// 휴대폰 알림 꺼짐 배너: 안내 + 탭하면 시스템 설정
class SystemNotificationPermissionBanner extends StatelessWidget {
  const SystemNotificationPermissionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: NotificationPermissionService().openSettings,
      scaleDown: AppPressable.scaleCard,
      enableRipple: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.errorBorder),
        ),
        child: Row(
          children: [
            Icon(AppIcons.alertOff, size: 20.sp, color: AppColors.warningRed),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '휴대폰 알림이 꺼져 있어요',
                    style: CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '설정에서 롬롬 알림을 허용해야 알림을 받을 수 있어요',
                    style: CustomTextStyles.p3.copyWith(color: AppColors.opacity60White, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              '설정 열기',
              style: CustomTextStyles.p3.copyWith(color: AppColors.primaryYellow, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
