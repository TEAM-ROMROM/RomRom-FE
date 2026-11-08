import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/sent_request_progress.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/widgets/common/app_tag.dart';

/// 보낸 요청 진행 태그: 대기·확인함·거절됨 (거래 상태 태그와 같은 크기, #1005)
class SentRequestProgressTag extends StatelessWidget {
  final SentRequestProgress progress;

  const SentRequestProgressTag({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final isRejected = progress == SentRequestProgress.rejected;
    return AppTag.tradeState(
      label: progress.label,
      backgroundColor: _toBackgroundColor(progress),
      textColor: isRejected ? AppColors.warningRed : AppColors.textColorWhite,
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
