// 채팅방 '여기까지 읽었어요' 구분선: 진입 시 안 읽은 첫 메시지 위 (양옆 선 + 가운데 문구)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class ChatUnreadDivider extends StatelessWidget {
  const ChatUnreadDivider({super.key});

  static const String label = '여기까지 읽었어요';

  @override
  Widget build(BuildContext context) {
    // 위쪽 간격은 메시지 그룹 간격과 동일
    return Padding(
      padding: EdgeInsets.only(top: 24.h),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.opacity20White, height: 1, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: CustomTextStyles.p3.copyWith(color: AppColors.primaryYellow, fontWeight: FontWeight.w500),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.opacity20White, height: 1, thickness: 1)),
        ],
      ),
    );
  }
}
