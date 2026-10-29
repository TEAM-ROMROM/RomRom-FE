import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 자동 새로고침 중에만 노출되는 얇은 progress 바.
/// 사용자가 능동으로 트리거한 게 아니라 스켈레톤 풀스크린 대신 얇은 바만 사용 (spec §2.1, §3.4).
class HomeFeedRefreshIndicator extends StatelessWidget {
  const HomeFeedRefreshIndicator({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return const SizedBox(
      height: 2,
      child: LinearProgressIndicator(
        minHeight: 2,
        backgroundColor: AppColors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
      ),
    );
  }
}
