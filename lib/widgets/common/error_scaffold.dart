import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';

/// 화면 단위 오류 표시: 뒤로 가기 앱바, 가운데 안내 문구, '다시 시도' 버튼(재시도 콜백 있을 때만)
/// 채팅방 초기화 실패·물품 상세 불러오기 실패 공용 (뒤로 가기 기본 동작: 현재 화면 pop)
class ErrorScaffold extends StatelessWidget {
  final String message;
  // null이면 문구만 표시 (예: 작성자 탈퇴 게시글)
  final VoidCallback? onRetry;
  // null이면 Navigator.pop(context)
  final VoidCallback? onBackPressed;

  const ErrorScaffold({super.key, required this.message, this.onRetry, this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: AppBar(backgroundColor: AppColors.primaryBlack, leading: _buildBackButton(context)),
      body: Center(child: onRetry == null ? _buildMessage() : _buildMessageWithRetry(onRetry!)),
    );
  }

  /// 원형 눌림 효과 뒤로 가기 버튼
  Widget _buildBackButton(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: ClipOval(
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onBackPressed ?? () => Navigator.pop(context),
          highlightColor: AppColors.buttonHighlightColorGray,
          splashColor: AppColors.buttonHighlightColorGray.withValues(alpha: 0.3),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(AppIcons.navigateBefore, color: AppColors.textColorWhite, semanticLabel: '뒤로 가기'),
          ),
        ),
      ),
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
        const SizedBox(height: 16),
        Material(
          color: AppColors.primaryYellow,
          borderRadius: BorderRadius.circular(4.r),
          child: InkWell(
            onTap: retry,
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
            highlightColor: darkenBlend(AppColors.primaryYellow),
            splashColor: darkenBlend(AppColors.primaryYellow).withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text('다시 시도', style: CustomTextStyles.p2.copyWith(color: AppColors.primaryBlack)),
            ),
          ),
        ),
      ],
    );
  }
}
