import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/gradient_text.dart';

/// AI 가격 분석 중 가격 필드 자리 표시: 분석 중 플레이스홀더(그라디언트 테두리 회전 + 쉬머) <-> 가격 필드 페이드 전환
/// 높이는 가격 필드 기준 (플레이스홀더는 필드 위에 겹쳐 그림)
class AiPriceAnalyzingField extends StatefulWidget {
  // 분석 중 문구 (테스트에서도 참조)
  static const String analyzingMessage = 'AI가 가격을 분석하고 있어요';

  // 테두리 회전·쉬머 1회 주기 (1.6초)
  static const int analyzingCycleMilliseconds = 1600;

  // 분석 중 <-> 가격 필드 전환 시간 (300ms)
  static const Duration fieldFadeDuration = AppMotion.normal;

  final bool isAnalyzing;
  final Widget priceField;

  const AiPriceAnalyzingField({super.key, required this.isAnalyzing, required this.priceField});

  @override
  State<AiPriceAnalyzingField> createState() => _AiPriceAnalyzingFieldState();
}

class _AiPriceAnalyzingFieldState extends State<AiPriceAnalyzingField> with SingleTickerProviderStateMixin {
  late final AnimationController _analyzingAnimationController;

  @override
  void initState() {
    super.initState();
    _analyzingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AiPriceAnalyzingField.analyzingCycleMilliseconds),
    );
    if (widget.isAnalyzing) _analyzingAnimationController.repeat();
  }

  @override
  void didUpdateWidget(covariant AiPriceAnalyzingField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 분석 중일 때만 반복 애니메이션 (그 외 정지)
    if (widget.isAnalyzing && !oldWidget.isAnalyzing) {
      _analyzingAnimationController.repeat();
    } else if (!widget.isAnalyzing && oldWidget.isAnalyzing) {
      _analyzingAnimationController.stop();
    }
  }

  @override
  void dispose() {
    _analyzingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 가격 필드: 분석 중 숨김·입력 차단, 완료 시 페이드 인
        AnimatedOpacity(
          opacity: widget.isAnalyzing ? 0 : 1,
          duration: AiPriceAnalyzingField.fieldFadeDuration,
          curve: AppMotion.entry,
          child: IgnorePointer(
            ignoring: widget.isAnalyzing,
            child: ExcludeSemantics(excluding: widget.isAnalyzing, child: widget.priceField),
          ),
        ),
        // 분석 중 플레이스홀더: 필드와 같은 크기로 겹침
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: AiPriceAnalyzingField.fieldFadeDuration,
            child: widget.isAnalyzing ? _buildAnalyzingPlaceholder() : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  /// 분석 중 플레이스홀더: 회전 그라디언트 테두리 > 쉬머 > AI 별 아이콘 + 그라디언트 문구
  Widget _buildAnalyzingPlaceholder() {
    return AnimatedBuilder(
      animation: _analyzingAnimationController,
      builder: (context, child) {
        final double animationProgress = _analyzingAnimationController.value;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.aiSuggestionContainerBackground,
            borderRadius: BorderRadius.circular(8.r),
            border: GradientBoxBorder(
              gradient: LinearGradient(
                colors: AppColors.aiGradient,
                stops: const [0.0, 0.35, 0.70, 1.0],
                transform: GradientRotation(animationProgress * 2 * math.pi),
              ),
              width: 1.5.w,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: DecoratedBox(decoration: _buildShimmerDecoration(animationProgress), child: child),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            SvgPicture.asset('assets/images/ai-recommend-price-star.svg', width: 16.w, height: 16.w),
            SizedBox(width: 8.w),
            Flexible(
              child: GradientText(
                text: AiPriceAnalyzingField.analyzingMessage,
                style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w600),
                gradient: const LinearGradient(colors: AppColors.aiGradient, stops: [0.0, 0.35, 0.70, 1.0]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 진행률(0~1) > 왼쪽 밖에서 오른쪽 밖으로 지나가는 흰 띠
  BoxDecoration _buildShimmerDecoration(double animationProgress) {
    // 띠 중심 위치: -2(왼쪽 밖) ~ 2(오른쪽 밖)
    final double shimmerCenter = -2 + 4 * animationProgress;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment(shimmerCenter - 1, 0),
        end: Alignment(shimmerCenter + 1, 0),
        colors: const [AppColors.transparent, AppColors.opacity20White, AppColors.transparent],
        stops: const [0.3, 0.5, 0.7],
      ),
    );
  }
}
