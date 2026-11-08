// 물품 검색 결과 목록: 결과 행, 끝 근처 스크롤 > 다음 페이지, 하단 로딩·다시 시도
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/states/item_search_state.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/item_search/item_search_result_tile.dart';

class ItemSearchResultList extends StatelessWidget {
  // 다음 페이지 요청 시작 지점 (끝에서 남은 스크롤 픽셀)
  static const double loadMoreTriggerExtentPixels = 300;

  final ItemSearchState searchState;
  final void Function(Item item, String heroTag) onItemTap;
  final VoidCallback onLoadMore;

  const ItemSearchResultList({super.key, required this.searchState, required this.onItemTap, required this.onLoadMore});

  /// 결과 행 Hero 태그 (상세 화면 이미지와 연결)
  static String toHeroTag(Item item) => 'itemSearch_${item.itemId}';

  @override
  Widget build(BuildContext context) {
    final items = searchState.items;
    final hasFooter = searchState.hasMore || searchState.hasNextPageError;
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        final isNearEnd = scrollNotification.metrics.extentAfter < loadMoreTriggerExtentPixels;
        if (isNearEnd && searchState.hasMore && !searchState.hasNextPageError) onLoadMore();
        return false;
      },
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
        itemCount: items.length + (hasFooter ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(color: AppColors.opacity10White, thickness: 1.5),
        itemBuilder: (context, index) {
          if (index == items.length) return _buildNextPageFooter();
          final searchResultItem = items[index];
          final heroTag = toHeroTag(searchResultItem);
          return ItemSearchResultTile(
            item: searchResultItem,
            heroTag: heroTag,
            onTap: () => onItemTap(searchResultItem, heroTag),
          );
        },
      ),
    );
  }

  /// 목록 하단: 다음 페이지 실패 > 다시 시도, 그 외 > 로딩
  Widget _buildNextPageFooter() {
    if (searchState.hasNextPageError) {
      return Center(
        child: TextButton(
          onPressed: onLoadMore,
          child: Text('다시 시도', style: CustomTextStyles.p2.copyWith(color: AppColors.primaryYellow)),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CommonLoadingIndicator(size: 20)),
    );
  }
}
