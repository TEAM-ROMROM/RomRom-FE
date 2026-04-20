import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 앱 전역 공통 로딩 스피너. CircularProgressIndicator 직접 사용 금지 — 이 위젯 사용.
class CommonLoadingIndicator extends StatelessWidget {
  const CommonLoadingIndicator({super.key, this.color = AppColors.primaryYellow, this.size = 24.0});

  /// 버튼 내부 흰색 스피너용 named constructor
  const CommonLoadingIndicator.white({super.key, this.size = 18.0}) : color = AppColors.textColorWhite;

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation<Color>(color)),
    );
  }
}
