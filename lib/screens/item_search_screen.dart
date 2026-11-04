import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_search_sort_field.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/item_search_query.dart';
import 'package:romrom_fe/providers/item_search_provider.dart';
import 'package:romrom_fe/providers/recent_search_keywords_provider.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/states/item_search_state.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';
import 'package:romrom_fe/widgets/common/item_category_multi_select_bottom_sheet.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/item_search/item_search_filter_bar.dart';
import 'package:romrom_fe/widgets/item_search/item_search_recent_keywords_view.dart';
import 'package:romrom_fe/widgets/item_search/item_search_result_list.dart';

/// 물품 검색 화면: 검색어 입력(제출 시 검색) > 카테고리·정렬 필터 > 결과 목록 (#1008)
/// 검색 전 최근 검색어, 결과 없음·실패는 공통 빈 상태 뷰, 필터 변경 시 같은 검색어로 다시 검색
class ItemSearchScreen extends ConsumerStatefulWidget {
  static const String keywordHintText = '어떤 물건을 찾으세요?';
  static const String emptyResultText = '검색 결과가 없어요';

  const ItemSearchScreen({super.key});

  @override
  ConsumerState<ItemSearchScreen> createState() => _ItemSearchScreenState();
}

class _ItemSearchScreenState extends ConsumerState<ItemSearchScreen> {
  final TextEditingController _keywordController = TextEditingController();
  final FocusNode _keywordFocusNode = FocusNode();
  List<ItemCategories> _selectedCategories = const [];
  ItemSearchSortField _selectedSortField = ItemSearchSortField.latest;

  @override
  void initState() {
    super.initState();
    _keywordController.addListener(_onKeywordChanged);
  }

  @override
  void dispose() {
    _keywordController.removeListener(_onKeywordChanged);
    _keywordController.dispose();
    _keywordFocusNode.dispose();
    super.dispose();
  }

  // 지우기 버튼 표시 갱신
  void _onKeywordChanged() => setState(() {});

  /// 검색 실행: 검색어 정리(빈 값 무시) > 최근 검색어 저장 > 현재 필터로 검색
  void _submitSearch(String keyword) {
    final trimmedKeyword = keyword.trim();
    if (trimmedKeyword.isEmpty) return;
    if (_keywordController.text != trimmedKeyword) _keywordController.text = trimmedKeyword;
    _keywordFocusNode.unfocus();
    ref.read(recentSearchKeywordsProvider.notifier).add(trimmedKeyword);
    ref
        .read(itemSearchProvider.notifier)
        .search(
          ItemSearchQuery(keyword: trimmedKeyword, categories: _selectedCategories, sortField: _selectedSortField),
        );
  }

  /// 필터 변경 후 다시 검색 (검색한 적 없으면 필터만 보관)
  void _researchWithCurrentFilters() {
    final searchedQuery = ref.read(itemSearchProvider).valueOrNull?.searchQuery;
    final keyword = searchedQuery?.keyword ?? _keywordController.text.trim();
    if (keyword.isEmpty) return;
    _submitSearch(keyword);
  }

  /// 카테고리 칩 탭 > 복수 선택 바텀시트 (제한 없음) > 완료 시 다시 검색
  Future<void> _onCategoryFilterTap() async {
    final pickedCategories = await ItemCategoryMultiSelectBottomSheet.show(
      context: context,
      title: '카테고리',
      initialCategories: _selectedCategories,
    );
    if (pickedCategories == null || !mounted) return;
    setState(() => _selectedCategories = pickedCategories);
    _researchWithCurrentFilters();
  }

  void _onSortFieldSelected(ItemSearchSortField sortField) {
    if (sortField == _selectedSortField) return;
    setState(() => _selectedSortField = sortField);
    _researchWithCurrentFilters();
  }

  /// 결과 행 탭 > 물품 상세 (검색 결과는 교환 가능 물품만)
  void _openItemDetail(Item item, String heroTag) {
    final itemId = item.itemId;
    if (itemId == null) return;
    context.navigateTo(
      screen: ItemDetailDescriptionScreen(
        itemId: itemId,
        imageSize: Size(MediaQuery.of(context).size.width, 400.h),
        currentImageIndex: 0,
        heroTag: heroTag,
        isMyItem: false,
        isRequestManagement: false,
        isTradeRequestAllowed: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            SizedBox(height: 12.h),
            ItemSearchFilterBar(
              selectedCategories: _selectedCategories,
              selectedSortField: _selectedSortField,
              onCategoryFilterTap: _onCategoryFilterTap,
              onSortFieldSelected: _onSortFieldSelected,
            ),
            SizedBox(height: 8.h),
            Expanded(child: _buildSearchBody()),
          ],
        ),
      ),
    );
  }

  /// 상단: 뒤로 가기 + 검색어 입력칸 (지우기 버튼)
  Widget _buildSearchHeader() {
    return Padding(
      padding: EdgeInsets.only(left: 8.w, right: 24.w, top: 8.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              AppIcons.navigateBefore,
              size: 24,
              color: AppColors.textColorWhite,
              semanticLabel: '뒤로 가기',
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(color: AppColors.opacity10White, borderRadius: BorderRadius.circular(8.r)),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _keywordController,
                      focusNode: _keywordFocusNode,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _submitSearch,
                      style: CustomTextStyles.p2,
                      cursorColor: AppColors.textColorWhite,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        hintText: ItemSearchScreen.keywordHintText,
                        hintStyle: CustomTextStyles.p2.copyWith(color: AppColors.opacity40White),
                      ),
                    ),
                  ),
                  if (_keywordController.text.isNotEmpty)
                    GestureDetector(
                      onTap: _keywordController.clear,
                      child: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.opacity40White),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 본문: 검색 전 > 최근 검색어, 로딩 > 스피너, 실패 > 다시 시도, 결과 없음 > 안내, 그 외 > 결과 목록
  Widget _buildSearchBody() {
    final searchAsync = ref.watch(itemSearchProvider);
    return searchAsync.when(
      loading: () => const Center(child: CommonLoadingIndicator()),
      error: (_, _) => EmptyStateView.error(onRetry: _researchWithCurrentFilters),
      data: (searchState) {
        if (!searchState.hasSearched) return _buildRecentKeywords();
        if (searchState.items.isEmpty) {
          return const EmptyStateView(
            icon: Icons.search_off_rounded,
            centerText: ItemSearchScreen.emptyResultText,
            descriptionText: '다른 검색어나 필터로 찾아보세요',
          );
        }
        return _buildResultList(searchState);
      },
    );
  }

  Widget _buildRecentKeywords() {
    final recentKeywords = ref.watch(recentSearchKeywordsProvider).valueOrNull ?? const <String>[];
    final recentKeywordsNotifier = ref.read(recentSearchKeywordsProvider.notifier);
    return ItemSearchRecentKeywordsView(
      recentKeywords: recentKeywords,
      onKeywordTap: _submitSearch,
      onKeywordRemove: recentKeywordsNotifier.remove,
      onClearAll: recentKeywordsNotifier.clear,
    );
  }

  Widget _buildResultList(ItemSearchState searchState) {
    return ItemSearchResultList(
      searchState: searchState,
      onItemTap: _openItemDetail,
      onLoadMore: ref.read(itemSearchProvider.notifier).loadMore,
    );
  }
}
