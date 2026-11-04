// 채팅 약속 카드: 상태 머리글·일시·장소, 수락(제안 받은 사람)·취소(양쪽) 버튼 (#1006)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/chat_appointment_status.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/chat_appointment.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';

// 버튼 위 간격·높이 (고정 px, 교환 요청 카드와 동일 > iPad에서 여백이 높이를 넘지 않게)
const double _appointmentButtonTopGap = 12;
const double _appointmentButtonHeight = 32;

class ChatAppointmentCard extends StatelessWidget {
  final ChatAppointment appointment;
  // 내가 제안한 약속인지 (머리글 문구)
  final bool isMine;
  final String opponentNickname;
  final double topGap;
  // 수락·취소 콜백 (버튼 노출 조건 불충족이면 null > 버튼 숨김)
  final VoidCallback? onAccept;
  final VoidCallback? onCancel;
  // 수락·취소 API 진행 중 (버튼 비활성)
  final bool isActionPending;

  const ChatAppointmentCard({
    super.key,
    required this.appointment,
    required this.isMine,
    required this.opponentNickname,
    required this.topGap,
    this.onAccept,
    this.onCancel,
    this.isActionPending = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCanceled = appointment.status == ChatAppointmentStatus.canceled;
    final Color contentColor = isCanceled ? AppColors.opacity50White : AppColors.primaryYellow;
    final appointmentAt = appointment.appointmentAt;

    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
        decoration: BoxDecoration(
          color: AppColors.exchangeRequestSystemMessageBackground,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: AppColors.exchangeRequestSystemMessageBorder,
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _headline,
              style: CustomTextStyles.p3.copyWith(fontSize: 13.sp, color: contentColor),
            ),
            SizedBox(height: 8.h),
            if (appointmentAt != null)
              _buildInfoRow(
                icon: Icons.schedule_outlined,
                text: formatAppointmentDateTime(appointmentAt),
                color: contentColor,
              ),
            SizedBox(height: 4.h),
            _buildInfoRow(icon: AppIcons.location, text: appointment.placeName ?? '', color: contentColor),
            if (onCancel != null || onAccept != null) _buildButtons(),
          ],
        ),
      ),
    );
  }

  /// 상태별 머리글 (모르는 상태 > '약속')
  String get _headline {
    switch (appointment.status) {
      case ChatAppointmentStatus.proposed:
        return isMine ? '약속을 제안했어요' : '$opponentNickname님이 약속을 제안했어요';
      case ChatAppointmentStatus.accepted:
        return '약속이 확정되었어요';
      case ChatAppointmentStatus.canceled:
        return '약속이 취소되었어요';
      case null:
        return '약속';
    }
  }

  Widget _buildInfoRow({required IconData icon, required String text, required Color color}) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: color),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: CustomTextStyles.p2.copyWith(color: color, fontWeight: FontWeight.w500, height: 1.2),
          ),
        ),
      ],
    );
  }

  /// 취소(회색)·수락(노랑) 버튼 줄
  Widget _buildButtons() {
    return Row(
      children: [
        if (onCancel != null)
          Expanded(child: _buildButton('취소하기', AppColors.opacity40White, AppColors.opacity20White, onCancel)),
        if (onCancel != null && onAccept != null) SizedBox(width: 7.w),
        if (onAccept != null)
          Expanded(child: _buildButton('수락하기', AppColors.primaryYellow, AppColors.opacity50PrimaryYellow, onAccept)),
      ],
    );
  }

  /// 카드 버튼 (진행 중이면 비활성 배경 + 탭 무시)
  Widget _buildButton(String label, Color backgroundColor, Color pendingBackgroundColor, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: _appointmentButtonTopGap),
      child: SizedBox(
        height: _appointmentButtonHeight,
        child: Material(
          color: isActionPending ? pendingBackgroundColor : backgroundColor,
          borderRadius: BorderRadius.circular(4.r),
          child: InkWell(
            onTap: isActionPending ? null : onTap,
            borderRadius: BorderRadius.circular(4.r),
            highlightColor: darkenBlend(backgroundColor),
            splashColor: darkenBlend(backgroundColor).withValues(alpha: 0.3),
            child: Center(
              child: Text(label, style: CustomTextStyles.p3.copyWith(color: AppColors.textColorBlack)),
            ),
          ),
        ),
      ),
    );
  }
}
