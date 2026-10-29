// 홈 카드 덱 카드 테두리·그림자: AI 추천 glow(펄스), hover/pulled 강조, 기본 그림자
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';

class HomeTabCardDecoration {
  HomeTabCardDecoration._();

  /// 카드 상태 3가지(AI 추천 glow, hover/pulled, 기본) > BoxDecoration (모서리 반경은 scale·카드 너비 비례)
  static BoxDecoration create({
    required bool isPulled,
    required bool isHovered,
    required bool isAiHighlighted,
    required double highlightPulse,
    required double scale,
    required double cardWidth,
  }) {
    return BoxDecoration(
      border: (isHovered || isPulled)
          ? Border.all(color: AppColors.primaryYellow, width: 2)
          : isAiHighlighted
          ? Border.all(
              color: AppColors.aiCardGradient[1].withValues(alpha: highlightPulse),
              width: 1.5.w,
            )
          : null,
      borderRadius: BorderRadius.circular(10 * scale * cardWidth / 219.0),
      boxShadow: _createBoxShadows(
        isPulled: isPulled,
        isHovered: isHovered,
        isAiHighlighted: isAiHighlighted,
        highlightPulse: highlightPulse,
      ),
    );
  }

  /// boxShadow 결정 (AI 추천 카드는 pulled/hovered 아닐 때만 glow)
  static List<BoxShadow> _createBoxShadows({
    required bool isPulled,
    required bool isHovered,
    required bool isAiHighlighted,
    required double highlightPulse,
  }) {
    if (isAiHighlighted && !isPulled && !isHovered) {
      // AI 추천 카드: aiCardGradient 색상 기반 glow (펄스 애니메이션)
      final pulse = highlightPulse;
      return [
        BoxShadow(
          color: AppColors.aiCardGradient[0].withValues(alpha: 0.75 * pulse),
          offset: Offset((-1).w, (-1).h),
          blurRadius: 6.r,
          spreadRadius: 4.r,
        ),
        BoxShadow(
          color: AppColors.aiCardGradient[1].withValues(alpha: 0.7 * pulse),
          offset: Offset(0, 5.h),
          blurRadius: 20.r,
          spreadRadius: 4.r,
        ),
        BoxShadow(
          color: AppColors.aiCardGradient[2].withValues(alpha: 0.65 * pulse),
          offset: Offset((-3).w, (-3).h),
          blurRadius: 10.r,
          spreadRadius: 3.r,
        ),
      ];
    }
    // 기본 / hover / pulled 상태
    return [
      BoxShadow(
        color: isHovered || isPulled ? AppColors.primaryBlack.withValues(alpha: 0.3) : AppColors.opacity20Black,
        blurRadius: isHovered || isPulled ? 20 : 10,
        spreadRadius: 0,
        offset: Offset(0, isHovered || isPulled ? 10 : 5),
      ),
    ];
  }
}
