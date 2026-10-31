// 물품 상세 상단 원형 아이콘 버튼 (보이는 크기 32, 터치·리플 캔버스 56) - 뒤로 가기·공유
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';

class ItemDetailCircleIconButton extends StatelessWidget {
  final IconData icon;
  // 아이콘 크기 (sp 적용 전 값)
  final double iconSize;
  final String semanticLabel;
  final VoidCallback onTap;
  // 바깥 32 박스 key (공유 시트 위치 기준 등)
  final Key? anchorKey;

  const ItemDetailCircleIconButton({
    super.key,
    required this.icon,
    required this.iconSize,
    required this.semanticLabel,
    required this.onTap,
    this.anchorKey,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: anchorKey,
      dimension: 32.w,
      child: OverflowBox(
        maxWidth: 56.w,
        maxHeight: 56.w,
        child: Material(
          color: AppColors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkResponse(
            onTap: onTap,
            radius: 18.w,
            customBorder: const CircleBorder(),
            highlightColor: AppColors.buttonHighlightColorGray.withValues(alpha: 0.5),
            splashColor: AppColors.buttonHighlightColorGray.withValues(alpha: 0.3),
            child: SizedBox.square(
              dimension: 56.w,
              child: Center(
                child: Icon(icon, size: iconSize.sp, color: AppColors.textColorWhite, semanticLabel: semanticLabel),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
