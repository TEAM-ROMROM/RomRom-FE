// 홈 탭 우측 상단 버튼 묶음: 알림(미확인 배지), 신고 메뉴
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/utils/app_test_keys.dart';
import 'package:romrom_fe/widgets/common/report_menu_button.dart';

/// 홈 탭 상단 버튼: 알림 아이콘(배지 여부 표시), 신고 메뉴, 탭 동작은 화면 콜백
class HomeTabTopActions extends StatelessWidget {
  // 미확인 알림 있으면 배지 아이콘
  final bool hasUnreadNotification;
  final VoidCallback onNotificationTap;
  final VoidCallback onReportPressed;

  const HomeTabTopActions({
    super.key,
    required this.hasUnreadNotification,
    required this.onNotificationTap,
    required this.onReportPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 32.w,
          child: OverflowBox(
            maxWidth: 56.w,
            maxHeight: 56.w,
            child: Material(
              color: AppColors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkResponse(
                key: AppTestKeys.homeNotificationButton,
                onTap: onNotificationTap,
                radius: 18.w,
                customBorder: const CircleBorder(),
                highlightColor: AppColors.buttonHighlightColorGray.withValues(alpha: 0.5),
                splashColor: AppColors.buttonHighlightColorGray.withValues(alpha: 0.3),
                child: SizedBox.square(
                  dimension: 56.w,
                  child: Center(
                    child: hasUnreadNotification
                        ? SvgPicture.asset(
                            'assets/images/alertWithBadge.svg',
                            width: 30.w,
                            height: 30.w,
                            semanticsLabel: '읽지 않은 알림 있음, 알림 목록',
                          )
                        : Icon(AppIcons.alert, size: 30.w, color: AppColors.textColorWhite, semanticLabel: '알림'),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: max(0.0, 10.w - ReportMenuButton.tapTargetExtraInset)),
        ReportMenuButton(onReportPressed: onReportPressed),
      ],
    );
  }
}
