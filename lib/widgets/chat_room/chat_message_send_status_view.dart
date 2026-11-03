// 내 메시지 전송 상태 표시: 전송 중 문구 / 실패 문구 + 다시 보내기·삭제
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/chat_message_send_status.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class ChatMessageSendStatusView extends StatelessWidget {
  // 전송 완료면 아무것도 표시하지 않음
  final ChatMessageSendStatus sendStatus;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;

  const ChatMessageSendStatusView({super.key, required this.sendStatus, this.onRetry, this.onDelete});

  @override
  Widget build(BuildContext context) {
    switch (sendStatus) {
      case ChatMessageSendStatus.sent:
        return const SizedBox.shrink();
      case ChatMessageSendStatus.sending:
        return Text('전송 중', style: _captionStyle(AppColors.opacity50White));
      case ChatMessageSendStatus.failed:
        return _buildFailedActions();
    }
  }

  /// 실패: 경고 문구 > 다시 보내기·삭제
  Widget _buildFailedActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.warning, size: 12.sp, color: AppColors.warningRed),
            SizedBox(width: 4.w),
            Text('전송 실패', style: _captionStyle(AppColors.warningRed)),
          ],
        ),
        SizedBox(height: 4.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionText(label: '다시 보내기', onTap: onRetry),
            SizedBox(width: 8.w),
            _buildActionText(label: '삭제', onTap: onDelete),
          ],
        ),
      ],
    );
  }

  Widget _buildActionText({required String label, required VoidCallback? onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Text(
          label,
          style: _captionStyle(AppColors.textColorWhite).copyWith(decoration: TextDecoration.underline),
        ),
      ),
    );
  }

  TextStyle _captionStyle(Color color) =>
      CustomTextStyles.p3.copyWith(fontSize: 12.sp, color: color, fontWeight: FontWeight.w400);
}
