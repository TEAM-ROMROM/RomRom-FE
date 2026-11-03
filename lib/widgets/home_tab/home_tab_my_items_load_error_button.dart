// 홈 탭 하단: 내 물품 불러오기 실패 안내 + 다시 시도 (카드 덱 자리)
import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';

/// 내 물품 조회 실패 버튼: 안내 문구 + 다시 시도 (재시도 중 스피너·탭 무시)
class HomeTabMyItemsLoadErrorButton extends StatelessWidget {
  final VoidCallback onRetryTap;
  final bool isRetrying;

  const HomeTabMyItemsLoadErrorButton({super.key, required this.onRetryTap, this.isRetrying = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppPressable(
        onTap: isRetrying ? null : onRetryTap,
        scaleDown: AppPressable.scaleButton,
        enableRipple: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.opacity80Black,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.opacity20White),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('내 물품을 불러오지 못했어요', style: CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite)),
              const SizedBox(width: 12),
              if (isRetrying)
                const CommonLoadingIndicator(size: 16)
              else
                Text(
                  '다시 시도',
                  style: CustomTextStyles.p2.copyWith(color: AppColors.primaryYellow, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
