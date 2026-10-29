// 채팅방 초기화 실패 화면: 뒤로 가기 앱바 + 오류 문구 + '다시 시도' 버튼
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';

class ChatRoomErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onBackPressed;
  final VoidCallback onRetry;

  const ChatRoomErrorView({super.key, required this.errorMessage, required this.onBackPressed, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlack,
        leading: Material(
          color: AppColors.transparent,
          child: ClipOval(
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBackPressed,
              highlightColor: AppColors.buttonHighlightColorGray,
              splashColor: AppColors.buttonHighlightColorGray.withValues(alpha: 0.3),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(AppIcons.navigateBefore, color: AppColors.textColorWhite, semanticLabel: '뒤로 가기'),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage,
              style: CustomTextStyles.p1.copyWith(color: AppColors.textColorWhite),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildRetryButton(),
          ],
        ),
      ),
    );
  }

  /// 노란 '다시 시도' 버튼
  Widget _buildRetryButton() {
    return Material(
      color: AppColors.primaryYellow,
      borderRadius: BorderRadius.circular(4.r),
      child: InkWell(
        onTap: onRetry,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
        highlightColor: darkenBlend(AppColors.primaryYellow),
        splashColor: darkenBlend(AppColors.primaryYellow).withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text('다시 시도', style: CustomTextStyles.p2.copyWith(color: AppColors.primaryBlack)),
        ),
      ),
    );
  }
}
