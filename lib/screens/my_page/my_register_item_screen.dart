import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/enums/my_item_toggle_status.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/widgets/common/app_fade_slide_in.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/services/app_event_bus.dart';
import 'package:romrom_fe/events/trade_completed_event.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/ai_badge.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/common/request_management_trade_option_tag.dart';
import 'package:romrom_fe/widgets/common/trade_status_tag.dart';
import 'package:romrom_fe/widgets/common/triple_toggle_switch.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/skeletons/register_tab_skeleton.dart';

class MyRegisterItemScreen extends StatefulWidget {
  const MyRegisterItemScreen({super.key});

  @override
  State<MyRegisterItemScreen> createState() => _MyRegisterItemScreenState();
}

class _MyRegisterItemScreenState extends State<MyRegisterItemScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  // 탭별 데이터
  final List<Item> _sellingItems = [];
  final List<Item> _completedItems = [];

  int _sellingPage = 0;
  int _completedPage = 0;
  bool _hasMoreSelling = true;
  bool _hasMoreCompleted = true;

  bool _isLoadingSelling = false;
  bool _isLoadingCompleted = false;
  bool _isLoadingMoreSelling = false;
  bool _isLoadingMoreCompleted = false;

  final int _pageSize = 20;

  // 전체 탭 getter
  List<Item> get _allItems => [..._sellingItems, ..._completedItems];

  // 토글 상태
  MyItemToggleStatus _currentTabStatus = MyItemToggleStatus.all;
  late AnimationController _toggleAnimationController;
  late Animation<double> _toggleAnimation;

  // 거래완료 이벤트 구독 (거래완료 시 판매중/거래완료 탭 재조회)
  StreamSubscription<TradeCompletedEvent>? _tradeCompletedSub;

  @override
  void initState() {
    super.initState();

    // 토글 애니메이션 초기화
    _toggleAnimationController = AnimationController(duration: AppMotion.normal, vsync: this, upperBound: 2.0);
    _toggleAnimation = _toggleAnimationController;

    _loadAllTabs();
    _scrollController.addListener(_scrollListener);
    // 거래완료 시 양쪽 탭 재조회 (거래완료된 물건이 판매중 → 거래완료로 이동 반영)
    _tradeCompletedSub = AppEventBus.instance.on<TradeCompletedEvent>().listen((_) {
      if (mounted) _loadAllTabs(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _tradeCompletedSub?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _toggleAnimationController.dispose();
    super.dispose();
  }

  /// selling/completed 두 탭을 병렬 로드
  Future<void> _loadAllTabs({bool isRefresh = false}) async {
    await Future.wait([
      _loadTabItems(MyItemToggleStatus.selling, isRefresh: isRefresh),
      _loadTabItems(MyItemToggleStatus.completed, isRefresh: isRefresh),
    ]);
  }

  /// 탭별 공통 로딩 함수
  Future<void> _loadTabItems(MyItemToggleStatus tab, {bool isRefresh = false}) async {
    assert(tab != MyItemToggleStatus.all, '_loadTabItems은 all 탭을 직접 호출하지 않음');

    final isSelling = tab == MyItemToggleStatus.selling;
    final isLoading = isSelling ? _isLoadingSelling : _isLoadingCompleted;
    final isLoadingMore = isSelling ? _isLoadingMoreSelling : _isLoadingMoreCompleted;
    final items = isSelling ? _sellingItems : _completedItems;

    if (!isRefresh && isLoading && items.isNotEmpty) return;
    if (!isRefresh && isLoadingMore) return;

    setState(() {
      if (isRefresh) {
        if (isSelling) {
          _sellingPage = 0;
          _hasMoreSelling = true;
          _sellingItems.clear();
          _isLoadingSelling = true;
        } else {
          _completedPage = 0;
          _hasMoreCompleted = true;
          _completedItems.clear();
          _isLoadingCompleted = true;
        }
      } else {
        if (isSelling) {
          _isLoadingSelling = true;
        } else {
          _isLoadingCompleted = true;
        }
      }
    });

    try {
      final itemApi = ItemApi();
      final currentPage = isSelling ? _sellingPage : _completedPage;
      final request = ItemRequest(
        pageNumber: isRefresh ? 0 : currentPage,
        pageSize: _pageSize,
        itemStatus: tab.serverName,
      );

      final response = await itemApi.getMyItems(request);
      final newItems = response.itemPage?.content ?? [];
      await Future.wait(newItems.map((item) => item.resolveAndCacheAddress()));

      if (mounted) {
        setState(() {
          if (isSelling) {
            _sellingItems.addAll(newItems);
            _hasMoreSelling = newItems.length == _pageSize;
            _isLoadingSelling = false;
          } else {
            _completedItems.addAll(newItems);
            _hasMoreCompleted = newItems.length == _pageSize;
            _isLoadingCompleted = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (isSelling) {
            _isLoadingSelling = false;
          } else {
            _isLoadingCompleted = false;
          }
        });

        CommonSnackBar.show(
          context: context,
          message: '물품 목록 로드 실패: ${ErrorUtils.getErrorMessage(e)}',
          type: SnackBarType.error,
        );
      }
    }
  }

  /// 더 많은 물품 로드 (페이징)
  Future<void> _loadMoreItems() async {
    switch (_currentTabStatus) {
      case MyItemToggleStatus.all:
        if (_hasMoreSelling && !_isLoadingMoreSelling) {
          await _loadMoreTab(MyItemToggleStatus.selling);
        }
        if (_hasMoreCompleted && !_isLoadingMoreCompleted) {
          await _loadMoreTab(MyItemToggleStatus.completed);
        }
      case MyItemToggleStatus.selling:
        if (_hasMoreSelling && !_isLoadingMoreSelling) {
          await _loadMoreTab(MyItemToggleStatus.selling);
        }
      case MyItemToggleStatus.completed:
        if (_hasMoreCompleted && !_isLoadingMoreCompleted) {
          await _loadMoreTab(MyItemToggleStatus.completed);
        }
    }
  }

  Future<void> _loadMoreTab(MyItemToggleStatus tab) async {
    final isSelling = tab == MyItemToggleStatus.selling;

    setState(() {
      if (isSelling) {
        _isLoadingMoreSelling = true;
      } else {
        _isLoadingMoreCompleted = true;
      }
    });

    try {
      final itemApi = ItemApi();
      final nextPage = (isSelling ? _sellingPage : _completedPage) + 1;
      final request = ItemRequest(pageNumber: nextPage, pageSize: _pageSize, itemStatus: tab.serverName);

      final response = await itemApi.getMyItems(request);
      final newItems = response.itemPage?.content ?? [];
      await Future.wait(newItems.map((item) => item.resolveAndCacheAddress()));

      if (mounted) {
        setState(() {
          if (isSelling) {
            _sellingItems.addAll(newItems);
            _sellingPage = nextPage;
            _hasMoreSelling = newItems.length == _pageSize;
            _isLoadingMoreSelling = false;
          } else {
            _completedItems.addAll(newItems);
            _completedPage = nextPage;
            _hasMoreCompleted = newItems.length == _pageSize;
            _isLoadingMoreCompleted = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (isSelling) {
            _isLoadingMoreSelling = false;
          } else {
            _isLoadingMoreCompleted = false;
          }
        });

        CommonSnackBar.show(
          context: context,
          message: '추가 물품 로드 실패: ${ErrorUtils.getErrorMessage(e)}',
          type: SnackBarType.error,
        );
      }
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: CommonAppBar(
        title: '나의 등록된 물건',
        appBarHeight: 120.h,
        bottomWidgets: PreferredSize(
          preferredSize: Size.fromHeight(62.h),
          child: TripleToggleSwitch(
            animation: _toggleAnimation,
            selectedIndex: _currentTabStatus.id,
            onFirstTap: () => _onToggleChanged(MyItemToggleStatus.all),
            onSecondTap: () => _onToggleChanged(MyItemToggleStatus.selling),
            onThirdTap: () => _onToggleChanged(MyItemToggleStatus.completed),
            firstText: '전체',
            secondText: '등록 물건',
            thirdText: '교환 완료',
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryYellow,
        backgroundColor: AppColors.transparent,
        onRefresh: () => _loadAllTabs(isRefresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [..._buildItemSlivers()],
        ),
      ),
    );
  }

  List<Widget> _buildItemSlivers() {
    final isLoading = _isLoadingSelling || _isLoadingCompleted;

    if (isLoading) {
      return const [RegisterTabSkeletonSliver()];
    }

    final displayItems = switch (_currentTabStatus) {
      MyItemToggleStatus.all => _allItems,
      MyItemToggleStatus.selling => _sellingItems,
      MyItemToggleStatus.completed => _completedItems,
    };

    if (displayItems.isEmpty) {
      return [SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())];
    }

    final hasMore = switch (_currentTabStatus) {
      MyItemToggleStatus.all => _hasMoreSelling || _hasMoreCompleted,
      MyItemToggleStatus.selling => _hasMoreSelling,
      MyItemToggleStatus.completed => _hasMoreCompleted,
    };

    final itemCountWithSeparators = displayItems.length * 2 - 1;

    return [
      SliverToBoxAdapter(
        child: Padding(padding: EdgeInsets.only(bottom: 16.h)),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index.isOdd) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0.w),
              child: Divider(thickness: 1.5, color: AppColors.opacity10White, height: 32.h),
            );
          }
          final item = displayItems[index ~/ 2];
          return AppFadeSlideIn(
            delay: Duration(milliseconds: (index ~/ 2) * AppMotion.staggerDelayMs),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0.w),
              child: _buildItemTile(item, index ~/ 2),
            ),
          );
        }, childCount: itemCountWithSeparators),
      ),
      if (hasMore)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: const Center(child: CommonLoadingIndicator()),
          ),
        ),
      SliverToBoxAdapter(child: SizedBox(height: 24.h)),
    ];
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    return Center(
      child: Text(
        '등록된 물건이 없어요.',
        style: CustomTextStyles.p1.copyWith(color: AppColors.opacity40White, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 실제 데이터 아이템 타일
  Widget _buildItemTile(Item item, int index) {
    final imageUrl = item.primaryImageUrl != null ? item.primaryImageUrl! : 'https://picsum.photos/400/300';
    final isAiPredictedPrice = item.isAiPredictedPrice ?? false;
    final tradeOptions = item.itemTradeOptions ?? const <String>[];
    final uploadTime = item.createdDate != null ? getTimeAgo(item.createdDate!) : 'Unknown';

    return Stack(
      children: [
        AppPressable(
          onTap: () => _navigateToItemDetail(item),
          scaleDown: AppPressable.scaleCard,
          enableRipple: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 이미지 썸네일
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: SizedBox(
                      width: 100.w,
                      height: 100.w,
                      child: item.itemId != null
                          ? Hero(tag: 'itemImage_${item.itemId}_0', child: _buildImage(imageUrl))
                          : _buildImage(imageUrl),
                    ),
                  ),
                  Positioned(
                    right: 4.w,
                    bottom: 4.h,
                    child: TradeStatusTagWidget(
                      status: item.itemStatus == ItemStatus.exchanged.serverName
                          ? TradeStatus.traded
                          : TradeStatus.pending,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 16.h),

              // 텍스트 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.itemName ?? '물품명 없음',
                      style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Text(
                          item.displayLocation,
                          style: CustomTextStyles.p3.copyWith(
                            color: AppColors.opacity60White,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          width: 4.w,
                          height: 4.w,
                          decoration: const BoxDecoration(color: AppColors.opacity60White, shape: BoxShape.circle),
                        ),
                        Text(
                          uploadTime,
                          style: CustomTextStyles.p3.copyWith(
                            color: AppColors.opacity60White,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // SizedBox(height: 12.h),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: isAiPredictedPrice ? 6.h : 8.h),
                      child: Row(
                        children: [
                          if (isAiPredictedPrice) const AiBadgeWidget(),
                          if (isAiPredictedPrice) SizedBox(width: 6.w),
                          Text('${formatPrice(item.price ?? 0)}원', style: CustomTextStyles.p1),
                        ],
                      ),
                    ),
                    Row(
                      children: tradeOptions
                          .map(
                            (option) => Padding(
                              padding: EdgeInsets.only(right: 4.w),
                              child: RequestManagementTradeOptionTag(option: ItemTradeOption.fromServerName(option)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 토글 상태 변경
  void _onToggleChanged(MyItemToggleStatus newStatus) {
    if (_currentTabStatus == newStatus) return;
    setState(() => _currentTabStatus = newStatus);
    _toggleAnimationController.animateTo(newStatus.id.toDouble(), duration: AppMotion.normal, curve: Curves.easeInOut);
  }

  /// 이미지 로드 위젯
  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return const ErrorImagePlaceholder();
    }

    return CachedImage(imageUrl: imageUrl.trim(), fit: BoxFit.cover, errorWidget: const ErrorImagePlaceholder());
  }

  /// 물품 상세 화면으로 이동
  Future<void> _navigateToItemDetail(Item item) async {
    if (item.itemId == null) return;

    final result = await context.navigateTo(
      screen: ItemDetailDescriptionScreen(
        itemId: item.itemId!,
        imageSize: Size(MediaQuery.of(context).size.width, 400.h),
        currentImageIndex: 0,
        heroTag: 'itemImage_${item.itemId}_0', // ← 인덱스 포함
        isMyItem: true,
        isRequestManagement: false,
      ),
    );

    // 상태 변경 또는 삭제 후 목록 새로고침
    if (result == true) {
      _loadAllTabs(isRefresh: true);
    }
  }
}
