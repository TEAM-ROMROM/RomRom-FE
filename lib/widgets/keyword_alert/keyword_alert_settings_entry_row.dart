import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/providers/keyword_alerts_provider.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';

/// 알림 설정 > 키워드 알림 진입 행: 제목·설명 + 등록 개수(불러온 뒤) + 오른쪽 화살표 (#1020)
class KeywordAlertSettingsEntryRow extends ConsumerWidget {
  final VoidCallback onTap;

  const KeywordAlertSettingsEntryRow({super.key, required this.onTap});

  static const String title = '키워드 알림';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registeredCount = ref.watch(keywordAlertsProvider.select((async) => async.valueOrNull?.registeredCount));
    return AppPressable(
      onTap: onTap,
      scaleDown: AppPressable.scaleCard,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
        padding: EdgeInsets.only(left: 16.w, right: 12.w, top: 16, bottom: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite)),
                  const SizedBox(height: 8),
                  Text(
                    '등록한 단어가 들어간 새 물품을 알려드려요',
                    style: CustomTextStyles.p3.copyWith(color: AppColors.opacity60White, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (registeredCount != null)
              Text(
                '$registeredCount개',
                style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White, fontWeight: FontWeight.w500),
              ),
            SizedBox(width: 4.w),
            Icon(Icons.chevron_right, size: 24.sp, color: AppColors.opacity60White, semanticLabel: '$title 설정 열기'),
          ],
        ),
      ),
    );
  }
}
