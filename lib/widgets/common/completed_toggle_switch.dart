import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';

/// 켜기·끄기 토글 스위치 (거래 완료 포함, 알림 설정)
/// 화면낭독기: 스위치 역할 + 켜짐 상태 + [semanticLabel], 터치 영역은 [touchAreaPadding]만큼 확장
class CompletedToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  // 화면낭독기 이름 (예: 알림 설정 항목명)
  final String? semanticLabel;
  // 스위치 둘레 추가 터치 여백 (배치 공간 있는 곳만, 기본 0 > 기존 배치 유지)
  final EdgeInsets touchAreaPadding;

  const CompletedToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.touchAreaPadding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: semanticLabel,
      onTap: () => onChanged(!value),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Padding(
          padding: touchAreaPadding,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            width: 40.w,
            height: 20.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              color: value ? AppColors.primaryYellow : AppColors.opacity40White, // 활성/비활성 색상
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: AppMotion.fast,
                  curve: AppMotion.standard,
                  left: value ? 19.w : 2.w,
                  top: 1.h,
                  child: Container(
                    width: 18.w,
                    height: 18.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.textColorWhite,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.toggleSwitchIndicatorShadow, // 검정 25%
                          blurRadius: 2.r,
                          offset: Offset(-1.w, 0),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
