import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/enums/my_item_toggle_status.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/widgets/common/app_fade_slide_in.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/ai_badge.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/widgets/common/request_management_trade_option_tag.dart';
import 'package:romrom_fe/widgets/common/trade_status_tag.dart';
import 'package:romrom_fe/widgets/common/triple_toggle_switch.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';
import 'package:romrom_fe/widgets/skeletons/register_tab_skeleton.dart';

class MyRegisterItemScreen extends ConsumerStatefulWidget {
  const MyRegisterItemScreen({super.key});

  @override
  ConsumerState<MyRegisterItemScreen> createState() => _MyRegisterItemScreenState();
}

class _MyRegisterItemScreenState extends ConsumerState<MyRegisterItemScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  // 불러오기 실패 뷰 재시도 진행 중 여부 (중복 탭 차단)
  bool _isRetryingMyItems = false;

  // 토글 상태
  MyItemToggleStatus _currentTabStatus = MyItemToggleStatus.all;
  late AnimationController _toggleAnimationController;
  late Animation<double> _toggleAnimation;

  @override
  void initState() {
    super.initState();

    _toggleAnimationController = AnimationController(duration: AppMotion.normal, vsync: this, upperBound: 2.0);
    _toggleAnimation = _toggleAnimationController;

    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _toggleAnimationController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // 스크롤 상태만 감지 (페이징 제거 — provider가 단일 소유)
  }

  @override
  Widget build(BuildContext context) {
    final myItemsAsync = ref.watch(myItemsProvider);
    final myItems = myItemsAsync.valueOrNull;
    final isLoading = myItemsAsync.isLoading && myItems == null;
    // 불러오기 실패 + 이전 값 없음 > 에러 뷰 (이전 값 있으면 목록 유지)
    final hasLoadErrorWithoutItems = myItemsAsync.hasError && myItems == null;

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: CommonAppBar(
        title: '나의 등록된 물품',
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
            secondText: '등록 물품',
            thirdText: '교환 완료',
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryYellow,
        backgroundColor: AppColors.transparent,
        onRefresh: () => ref.read(myItemsProvider.notifier).reload(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            ..._buildItemSlivers(
              isLoading: isLoading,
              hasLoadErrorWithoutItems: hasLoadErrorWithoutItems,
              myItems: myItems,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItemSlivers({required bool isLoading, required bool hasLoadErrorWithoutItems, required myItems}) {
    if (isLoading) {
      return const [RegisterTabSkeletonSliver()];
    }

    if (hasLoadErrorWithoutItems) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView.error(
            centerText: '물품을 불러오지 못했어요',
            onRetry: _onRetryMyItemsPressed,
            isRetrying: _isRetryingMyItems,
          ),
        ),
      ];
    }

    final List<Item> displayItems = switch (_currentTabStatus) {
      MyItemToggleStatus.all => [...(myItems?.available ?? []), ...(myItems?.exchanged ?? [])],
      MyItemToggleStatus.selling => myItems?.available ?? const [],
      MyItemToggleStatus.completed => myItems?.exchanged ?? const [],
    };

    if (displayItems.isEmpty) {
      return [SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())];
    }

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
      SliverToBoxAdapter(child: SizedBox(height: 24.h)),
    ];
  }

  /// 불러오기 실패 뷰 재시도: 중복 탭 차단 > 서버 재조회
  Future<void> _onRetryMyItemsPressed() async {
    if (_isRetryingMyItems) return;
    setState(() => _isRetryingMyItems = true);
    try {
      await ref.read(myItemsProvider.notifier).reload();
    } finally {
      if (mounted) setState(() => _isRetryingMyItems = false);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        '등록된 물품이 없어요.',
        style: CustomTextStyles.p1.copyWith(color: AppColors.opacity40White, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildItemTile(Item item, int index) {
    final imageUrl = item.primaryImageUrl ?? '';
    final isAiPredictedPrice = item.isAiPredictedPrice ?? false;
    final tradeOptions = item.itemTradeOptions ?? const <String>[];
    final uploadTime = item.createdDate != null ? getTimeAgo(item.createdDate!) : '';

    return Stack(
      children: [
        AppPressable(
          onTap: () => _navigateToItemDetail(item),
          scaleDown: AppPressable.scaleCard,
          enableRipple: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                        if (uploadTime.isNotEmpty) ...[
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
                      ],
                    ),
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

  void _onToggleChanged(MyItemToggleStatus newStatus) {
    if (_currentTabStatus == newStatus) return;
    setState(() => _currentTabStatus = newStatus);
    _toggleAnimationController.animateTo(newStatus.id.toDouble(), duration: AppMotion.normal, curve: Curves.easeInOut);
  }

  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return const ErrorImagePlaceholder();
    }
    return CachedImage(imageUrl: imageUrl.trim(), fit: BoxFit.cover, errorWidget: const ErrorImagePlaceholder());
  }

  Future<void> _navigateToItemDetail(Item item) async {
    if (item.itemId == null) return;
    await context.navigateTo(
      screen: ItemDetailDescriptionScreen(
        itemId: item.itemId!,
        imageSize: Size(MediaQuery.of(context).size.width, 400.h),
        currentImageIndex: 0,
        heroTag: 'itemImage_${item.itemId}_0',
        isMyItem: true,
        isRequestManagement: false,
      ),
    );
    // 상태 변경/삭제 시 myItemsProvider가 notifier 경유로 자동 갱신
  }
}
