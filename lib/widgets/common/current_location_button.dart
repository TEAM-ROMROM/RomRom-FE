import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 현재 위치로 이동 버튼 위젯
/// 지도 화면 등에서 재사용 가능
class CurrentLocationButton extends StatelessWidget {
  /// 버튼 클릭 시 실행할 콜백
  final VoidCallback? onTap;

  /// 아이콘 크기
  final double iconSize;

  /// 외부 마진
  final EdgeInsetsGeometry? margin;

  const CurrentLocationButton({
    super.key,
    this.onTap,
    this.iconSize = 24.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.currentLocationButtonBg,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.currentLocationButtonBorder,
          width: 0.15.w,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppColors.currentLocationButtonShadow.withValues(alpha: 0.25),
            blurRadius: 2.0,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color:
                AppColors.currentLocationButtonShadow.withValues(alpha: 0.25),
            blurRadius: 2.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        iconSize: iconSize,
        icon: const Icon(
          AppIcons.currentLocation,
          color: AppColors.currentLocationButtonIcon,
        ),
      ),
    );
  }
}
