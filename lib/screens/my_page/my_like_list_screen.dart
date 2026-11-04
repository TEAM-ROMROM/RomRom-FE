import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_fade_slide_in.dart';
import 'package:romrom_fe/providers/current_tab_index_provider.dart';
import 'package:romrom_fe/providers/item_address_resolver_provider.dart';
import 'package:romrom_fe/providers/item_like_provider.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/utils/list_ad_placement.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/widgets/item_detail_condition_tag.dart';
import 'package:romrom_fe/widgets/item_detail_trade_option_tag.dart';
import 'package:romrom_fe/widgets/list_native_ad/list_native_ad_cell.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/skeletons/my_like_list_skeleton.dart';

class MyLikeListScreen extends ConsumerStatefulWidget {
  const MyLikeListScreen({super.key});

  @override
  ConsumerState<MyLikeListScreen> createState() => _MyLikeListScreenState();
}

class _MyLikeListScreenState extends ConsumerState<MyLikeListScreen> {
  final List<_LikedItem> _items = [];

  int _currentPage = 0; // next page to request (0-based)
  final int _pageSize = 10;

  bool _isLoading = false;
  bool _hasMoreItems = true;

  // 처음부터 다시 불러오기(reset) 실패 여부 (목록 비어 있으면 에러 뷰)
  bool _hasResetLoadError = false;

  // 다음 페이지 불러오기 실패 여부 (true면 하단 다시 시도, 스크롤 자동 재요청 멈춤)
  bool _hasNextPageLoadError = false;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadLikeItems(reset: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final pos = _scrollController.position;
    const threshold = 200.0;

    if (pos.pixels >= pos.maxScrollExtent - threshold) {
      if (!_isLoading && _hasMoreItems && !_hasNextPageLoadError) {
        _loadLikeItems(reset: false);
      }
    }
  }

  /// Like 목록 로드 (reset: true -> 처음부터 다시 로드)
  Future<void> _loadLikeItems({required bool reset}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final pageToRequest = reset ? 0 : _currentPage;
      final serverItems = await ref
          .read(itemRepositoryProvider)
          .getLikedItems(pageNumber: pageToRequest, pageSize: _pageSize);
      final likeItems = await _convertToLikeItems(serverItems);

      if (!mounted) return;

      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(likeItems);
        } else {
          _items.addAll(likeItems);
        }

        // 다음에 요청할 페이지
        _currentPage = pageToRequest + 1;

        // 서버가 pageSize보다 적게 보내면 → 더 없음
        _hasMoreItems = serverItems.length == _pageSize;
        if (reset) _hasResetLoadError = false;
        _hasNextPageLoadError = false;
      });

      // 캐시 시드 (force=true: 좋아요 목록은 항상 isLiked=true 진실원천)
      // likeCount는 서버 응답에 포함된 값 사용 (없으면 0)
      final likeCountById = {
        for (final si in serverItems)
          if (si.itemId != null) si.itemId!: si.likeCount ?? 0,
      };
      for (final it in likeItems) {
        ref
            .read(itemLikeProvider.notifier)
            .seed(itemId: it.itemId, isLiked: true, likeCount: likeCountById[it.itemId] ?? 0, force: true);
      }
    } catch (e) {
      debugPrint('사용자 좋아요 목록 로드 실패: $e');
      if (!mounted) return;
      // 다음 페이지 실패 > 하단 다시 시도 + 안내
      if (!reset) {
        setState(() => _hasNextPageLoadError = true);
        CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
        return;
      }
      setState(() => _hasResetLoadError = true);
      // 기존 목록 있음 > 목록 유지 + 스낵바 (없으면 에러 뷰가 대신 표시)
      if (_items.isNotEmpty) {
        CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 서버 물품 목록 > 좋아요 목록 표시 항목 (주소 병렬 변환)
  Future<List<_LikedItem>> _convertToLikeItems(List<Item> details) async {
    List<_LikedItem> likeItems = <_LikedItem>[];
    // 주소 변환 병렬 처리 (결과 순서 = 입력 순서)
    final locationTexts = await ref.read(itemAddressResolverProvider).resolveLocationTexts(details);

    for (int index = 0; index < details.length; index++) {
      final d = details[index];

      // 모르는·없는 물품 상태 > 미개봉
      final cond = ItemCondition.fromServerName(d.itemCondition) ?? ItemCondition.sealed;
      final opts = ItemTradeOption.fromServerNamesSkippingUnknown(d.itemTradeOptions);

      final likeItem = _LikedItem(
        itemId: d.itemId ?? 'unknown_$index',
        heroTag: 'itemImage_${d.itemId}_0',
        title: d.itemName ?? '제목 없음',
        location: locationTexts[index],
        itemStatus: d.itemStatus ?? 'unknown',
        imageUrl: (d.imageUrlList.isNotEmpty) ? d.imageUrlList.first : '',
        price: d.price ?? 0,
        tags: [cond.label, ...opts.map((e) => e.label)],
        isLiked: true,
      );

      likeItems.add(likeItem);
    }

    return likeItems;
  }

  /// 홈에서 둘러보기: 홈 탭 지정 > 첫 화면(MainScreen)까지 닫기 (마이페이지 탭으로 돌아가는 것 방지)
  void _navigateToHomeTab() {
    ref.read(currentTabIndexProvider.notifier).set(0);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // 좋아요 목록 행 구분선 (행 사이·광고 칸 아래 공통)
  static const Widget _likeListDivider = Divider(color: AppColors.opacity10White, thickness: 1.5);

  // 좋아요 해제한 물품은 빈 하트로 목록에 남김 (다시 눌러 되돌리기 가능, 새로고침·재진입 시 정리)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: CommonAppBar(title: '좋아요 목록', showBottomBorder: true, onBackPressed: () => Navigator.pop(context)),
      body: RefreshIndicator(
        color: AppColors.primaryYellow,
        backgroundColor: AppColors.transparent,
        onRefresh: () => _loadLikeItems(reset: true),
        child: _buildLikeListBody(),
      ),
    );
  }

  /// 상태별 본문: 첫 로딩 스켈레톤 / 에러 뷰 / 빈 상태 / 목록
  Widget _buildLikeListBody() {
    if (_items.isEmpty && _isLoading) {
      return const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: MyLikeListSkeleton());
    }

    if (_items.isEmpty && _hasResetLoadError) {
      return _buildPullableFillView(
        child: EmptyStateView.error(centerText: '좋아요 목록을 불러오지 못했어요', onRetry: () => _loadLikeItems(reset: true)),
      );
    }

    if (_items.isEmpty) {
      return _buildPullableFillView(
        child: EmptyStateView(
          icon: AppIcons.profilelikecount,
          centerText: '아직 좋아요한 물품이 없어요',
          descriptionText: '마음에 드는 물품을 찾아\n좋아요를 눌러보세요',
          buttonText: '홈에서 둘러보기',
          onButtonTap: _navigateToHomeTab,
        ),
      );
    }

    final listItemCount = ListAdPlacement.itemList.listItemCount(_items.length);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: listItemCount + (_hasMoreItems ? 1 : 0),
        // 광고 칸 아래 구분선은 광고 칸이 함께 그림 (실패로 접히면 구분선도 접혀 중복 없음)
        separatorBuilder: (_, listIndex) => ListAdPlacement.itemList.isAdAtListIndex(listIndex, _items.length)
            ? const SizedBox.shrink()
            : _likeListDivider,
        itemBuilder: (context, listIndex) {
          // 마지막 행: 다음 페이지 하단 (실패 시 다시 시도, 그 외 로딩)
          if (_hasMoreItems && listIndex == listItemCount) {
            return _buildNextPageFooter();
          }
          // 8개마다 광고 1칸 (마지막 칸이면 아래 구분선 없음)
          if (ListAdPlacement.itemList.isAdAtListIndex(listIndex, _items.length)) {
            final isLastListEntry = !_hasMoreItems && listIndex == listItemCount - 1;
            return ListNativeAdCell(
              key: ValueKey('like_list_ad_$listIndex'),
              bottomSeparator: isLastListEntry ? null : _likeListDivider,
            );
          }
          final index = ListAdPlacement.itemList.contentIndexAtListIndex(listIndex);
          final item = _items[index];

          return AppFadeSlideIn(
            delay: Duration(milliseconds: index * AppMotion.staggerDelayMs),
            child: GestureDetector(
              onTap: () async {
                final itemId = item.itemId;
                await context.navigateTo(
                  screen: ItemDetailDescriptionScreen(
                    itemId: itemId,
                    imageSize: Size(MediaQuery.of(context).size.width, 400.h),
                    currentImageIndex: 0,
                    heroTag: 'itemImage_${itemId}_0',
                    isMyItem: false,
                    isRequestManagement: false,
                    isTradeRequestAllowed: true,
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: const BoxDecoration(color: AppColors.transparent),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 썸네일 (Hero 적용)
                    Hero(
                      tag: item.heroTag,
                      transitionOnUserGestures: true,
                      createRectTween: (begin, end) => MaterialRectArcTween(begin: begin, end: end),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Stack(
                          children: [
                            Container(
                              width: 70.w,
                              height: 70.w,
                              color: AppColors.opacity10White,
                              child: item.imageUrl.isEmpty
                                  ? const Icon(Icons.photo_size_select_actual_rounded, color: AppColors.opacity40White)
                                  : CachedImage(imageUrl: item.imageUrl, fit: BoxFit.cover),
                            ),

                            /// 거래완료 오버레이 (검정 50%)
                            if (item.itemStatus == ItemStatus.exchanged.serverName)
                              IgnorePointer(
                                child: Container(width: 70.w, height: 70.w, color: AppColors.opacity50Black),
                              ),

                            /// 거래완료 글라스모피즘 배지 (이미지 중앙)
                            if (item.itemStatus == ItemStatus.exchanged.serverName)
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4.r),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                      child: Container(
                                        width: 50.w,
                                        height: 20.h,
                                        decoration: BoxDecoration(
                                          color: AppColors.opacity10White,
                                          borderRadius: BorderRadius.circular(4.r),
                                          border: Border.all(color: AppColors.textColorWhite, width: 1.w),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '교환 완료',
                                          style: CustomTextStyles.p3.copyWith(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textColorWhite,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // 정보
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            item.location,
                            style: CustomTextStyles.p3.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.opacity60White,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text('${formatPrice(item.price)}원', style: CustomTextStyles.p1),
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 6.h,
                                children: [
                                  // tags 배열을 (condition, options...) 구조로 가정
                                  if (item.tags.isNotEmpty)
                                    // 첫 번째는 condition
                                    ItemDetailConditionTag(condition: item.tags.first),
                                  // 나머지는 trade option들
                                  ...item.tags.skip(1).map((opt) => ItemDetailTradeOptionTag(option: opt)),
                                ],
                              ),
                              // 좋아요 버튼 (아이콘+원)
                              GestureDetector(
                                onTap: () async {
                                  // 해제·재등록 모두 같은 토글 (실패 시 SnackBar는 itemLikeProvider에서 자동 표시)
                                  await ref.read(itemLikeProvider.notifier).toggle(item.itemId);
                                },
                                child: Center(
                                  child: Builder(
                                    builder: (context) {
                                      final liked = ref.watch(
                                        itemLikeProvider.select((s) => s[item.itemId]?.isLiked ?? item.isLiked),
                                      );
                                      return Icon(
                                        liked ? AppIcons.itemRegisterHeart : AppIcons.profilelikecount,
                                        color: AppColors.textColorWhite,
                                        size: 24.sp,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 목록 하단: 다음 페이지 실패 > 다시 시도, 그 외 > 로딩 스피너
  Widget _buildNextPageFooter() {
    if (_hasNextPageLoadError) {
      return Center(
        child: TextButton(
          onPressed: _isLoading ? null : () => _loadLikeItems(reset: false),
          child: Text('다시 시도', style: CustomTextStyles.p2.copyWith(color: AppColors.primaryYellow)),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CommonLoadingIndicator(size: 20)),
    );
  }

  /// 당겨서 새로고침 가능한 화면 채움 뷰 (빈 상태·에러 뷰용, 내용이 짧아도 pull 동작)
  Widget _buildPullableFillView({required Widget child}) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
    );
  }
}

class _LikedItem {
  final String itemId;
  final String heroTag;
  final String title;
  final String location;
  final String itemStatus;
  final List<String> tags;
  final String imageUrl;
  final int price;
  bool isLiked;

  _LikedItem({
    required this.itemId,
    required this.heroTag,
    required this.title,
    required this.location,
    required this.itemStatus,
    required this.tags,
    required this.imageUrl,
    required this.price,
    required this.isLiked,
  });
}
