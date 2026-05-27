import 'package:flutter/material.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/services/app_review_service.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';

/// 앱 리뷰 유도 2단계 팝업 시퀀스
/// Step 1: "잘 이용하고 계신가요?" 감성 질문
/// Step 2: [좋아요] 선택 시 → "스토어 리뷰 남겨주실래요?"
class AppReviewPopup {
  /// 팝업 시퀀스 실행
  /// context가 mounted 상태인지 호출 전 반드시 확인할 것
  static Future<void> show(BuildContext context, AppReviewService service) async {
    // 노출 기록 (Step 1이 뜨는 시점)
    await service.markShown();

    if (!context.mounted) return;

    // Step 1: 감성 질문 팝업
    final isPositive = await _showStep1(context);

    if (!isPositive) return;

    if (!context.mounted) return;

    // Step 2: 리뷰 유도 팝업
    final wantsReview = await _showStep2(context);

    if (wantsReview) {
      await service.requestReviewAndDisable();
    }
  }

  /// Step 1: "RomRom을 잘 이용하고 계신가요?"
  /// 반환값: true = [좋아요!], false = [별로예요] or 닫기
  static Future<bool> _showStep1(BuildContext context) async {
    final result = await CommonModal.confirm(
      context: context,
      message: 'RomRom을 잘 이용하고 계신가요?\n소중한 의견이 앱 개선에 도움이 됩니다 😊',
      cancelText: '별로예요',
      confirmText: '좋아요!',
      icon: AppIcons.information,
      iconColor: AppColors.primaryYellow,
      confirmButtonColor: AppColors.primaryYellow,
      confirmTextColor: AppColors.textColorBlack,
      onCancel: () => Navigator.of(context).pop(false),
      onConfirm: () => Navigator.of(context).pop(true),
    );
    return result ?? false;
  }

  /// Step 2: "스토어 리뷰를 남겨주실래요?"
  /// 반환값: true = [리뷰 남기기], false = [나중에] or 닫기
  static Future<bool> _showStep2(BuildContext context) async {
    final result = await CommonModal.confirm(
      context: context,
      message: '별점 한 줄이 큰 힘이 됩니다! ⭐\n스토어에 리뷰를 남겨주실래요?',
      cancelText: '나중에',
      confirmText: '리뷰 남기기',
      icon: AppIcons.information,
      iconColor: AppColors.primaryYellow,
      confirmButtonColor: AppColors.primaryYellow,
      confirmTextColor: AppColors.textColorBlack,
      onCancel: () => Navigator.of(context).pop(false),
      onConfirm: () => Navigator.of(context).pop(true),
    );
    return result ?? false;
  }
}
