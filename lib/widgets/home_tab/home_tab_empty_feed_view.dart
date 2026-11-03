// 홈 탭 피드 빈 상태: 안내 문구, 새로고침(진행 중 스피너), 탐색 범위 넓히기
import 'package:flutter/material.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';

/// 홈 탭 빈 피드: 새로고침·탐색 범위 넓히기 탭은 화면 콜백
class HomeTabEmptyFeedView extends StatelessWidget {
  final VoidCallback onRefreshTap;
  final VoidCallback onExpandSearchRangeTap;

  // 새로고침 진행 중 여부 (true면 스피너 + 탭 무시)
  final bool isRefreshing;

  const HomeTabEmptyFeedView({
    super.key,
    required this.onRefreshTap,
    required this.onExpandSearchRangeTap,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: AppIcons.home,
      centerText: '주변에 교환할 물품이 없어요',
      descriptionText: '탐색 범위를 넓히면\n더 많은 물품을 볼 수 있어요',
      buttonText: '새로고침',
      onButtonTap: onRefreshTap,
      isButtonLoading: isRefreshing,
      secondaryButtonText: '탐색 범위 넓히기',
      onSecondaryButtonTap: onExpandSearchRangeTap,
    );
  }
}
