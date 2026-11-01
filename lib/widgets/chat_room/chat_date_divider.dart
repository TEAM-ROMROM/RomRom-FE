// 채팅방 날짜 구분선: 날짜가 바뀌는 메시지 위에 가운데 정렬 알약 라벨 (예: 2026년 11월 1일 일요일)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/date_time_display_utils.dart';

class ChatDateDivider extends StatelessWidget {
  final DateTime date;

  const ChatDateDivider({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    // 알약 내부 여백은 고정 px (iPad 확대 방지), 위쪽 간격은 메시지 그룹 간격과 동일
    return Padding(
      padding: EdgeInsets.only(top: 24.h),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppColors.opacity10White, borderRadius: BorderRadius.circular(100)),
          child: Text(
            formatChatDateDividerLabel(date),
            style: CustomTextStyles.p3.copyWith(color: AppColors.opacity60White, fontWeight: FontWeight.w400),
          ),
        ),
      ),
    );
  }
}
