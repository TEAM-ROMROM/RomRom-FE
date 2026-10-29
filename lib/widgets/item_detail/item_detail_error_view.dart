// 물품 상세 오류 화면: 뒤로 가기 앱바 + 안내 문구 (재시도 콜백 있으면 '다시 시도' 버튼)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';

class ItemDetailErrorView extends StatelessWidget {
  final String message;
  // null이면 문구만 표시 (예: 작성자 탈퇴 게시글)
  final VoidCallback? onRetry;

  const ItemDetailErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        leading: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            customBorder: const CircleBorder(),
            highlightColor: AppColors.buttonHighlightColorGray,
            splashColor: AppColors.buttonHighlightColorGray.withValues(alpha: 0.3),
            child: const Icon(AppIcons.navigateBefore, color: AppColors.textColorWhite, semanticLabel: '뒤로 가기'),
          ),
        ),
      ),
      body: Center(child: onRetry == null ? _buildMessage() : _buildMessageWithRetry(onRetry!)),
    );
  }

  Widget _buildMessage() {
    return Text(
      message,
      style: CustomTextStyles.p1.copyWith(color: AppColors.textColorWhite),
      textAlign: TextAlign.center,
    );
  }

  /// 안내 문구 + 노란 '다시 시도' 버튼
  Widget _buildMessageWithRetry(VoidCallback retry) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildMessage(),
        SizedBox(height: 16.h),
        Material(
          color: AppColors.primaryYellow,
          borderRadius: BorderRadius.circular(4.r),
          child: InkWell(
            onTap: retry,
            highlightColor: darkenBlend(AppColors.primaryYellow),
            splashColor: darkenBlend(AppColors.primaryYellow).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              child: Text('다시 시도', style: CustomTextStyles.p2.copyWith(color: AppColors.primaryBlack)),
            ),
          ),
        ),
      ],
    );
  }
}
