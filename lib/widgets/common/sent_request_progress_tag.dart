import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/sent_request_progress.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_tag.dart';

/// 보낸 요청 진행 태그: 대기·확인함·거절됨 (거래 상태 태그와 같은 크기, #1005)
class SentRequestProgressTag extends StatelessWidget {
  final SentRequestProgress progress;

  const SentRequestProgressTag({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final isRejected = progress == SentRequestProgress.rejected;
    return AppTag(
      label: progress.label,
      alignment: Alignment.center,
      width: 60.w,
      height: 23.h,
      borderRadius: 4.r,
      backgroundColor: _toBackgroundColor(progress),
      textStyle: CustomTextStyles.p3.copyWith(
        fontSize: 10.sp,
        color: isRejected ? AppColors.warningRed : AppColors.textColorWhite,
      ),
    );
  }

  /// 진행 상태 > 태그 배경색
  static Color _toBackgroundColor(SentRequestProgress progress) {
    return switch (progress) {
      SentRequestProgress.waiting => AppColors.sentRequestProgressWaiting,
      SentRequestProgress.checked => AppColors.sentRequestProgressChecked,
      SentRequestProgress.rejected => AppColors.sentRequestProgressRejected,
    };
  }
}
