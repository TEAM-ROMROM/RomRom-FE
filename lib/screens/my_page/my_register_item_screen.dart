import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/enums/my_item_toggle_status.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/common/trade_status_tag.dart';
import 'package:romrom_fe/widgets/skeletons/register_tab_skeleton.dart';
import 'package:romrom_fe/widgets/common/glass_header_delegate.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'dart:async';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';

import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/utils/error_utils.dart';

class MyRegisterItemScreen extends StatefulWidget {
  const MyRegisterItemScreen({super.key});

  @override
  State<MyRegisterItemScreen> createState() => _MyRegisterItemScreenState();
}

class _MyRegisterItemScreenState extends State<MyRegisterItemScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false; //
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreItems = true;
  Timer? _scrollTimer;

  // 내 물품 데이터
  final List<Item> _myItems = [];
  int _currentPage = 0;
  final int _pageSize = 20;

  // 토글 상태
  MyItemToggleStatus _currentTabStatus = MyItemToggleStatus.selling;
  late AnimationController _toggleAnimationController;
  late Animation<double> _toggleAnimation;

  @override
  void initState() {
    super.initState();

    // 토글 애니메이션 초기화
    _toggleAnimationController = AnimationController(duration: AppMotion.normal, vsync: this);
    _toggleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _toggleAnimationController, curve: AppMotion.standard));

    _loadMyItems();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _toggleAnimationController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }

  /// 내 물품 목록 로드 (초기 로딩)
  Future<void> _loadMyItems({bool isRefresh = false}) async {
    debugPrint('_loadMyItems 호출됨: isRefresh=$isRefresh, _isLoading=$_isLoading');

    // 초기 로딩이 아닌 경우에만 중복 호출 방지
    if (!isRefresh && _isLoading && _myItems.isNotEmpty) {
      debugPrint('중복 로딩 방지로 return');
      return;
    }

    setState(() {
      if (isRefresh) {
        _currentPage = 0;
        _hasMoreItems = true;
        _myItems.clear();
      }
      _isLoading = true;
    });

    try {
      final itemApi = ItemApi();
      final request = ItemRequest(
        pageNumber: isRefresh ? 0 : _currentPage,
        pageSize: _pageSize,
        itemStatus: _currentTabStatus.serverName,
      );

      final response = await itemApi.getMyItems(request);
      final newItems = response.itemPage?.content ?? [];

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _myItems.clear();
            _currentPage = 0;
          }

          _myItems.addAll(newItems);
          _hasMoreItems = newItems.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        CommonSnackBar.show(
          context: context,
          message: '내 물품 목록 로드 실패: ${ErrorUtils.getErrorMessage(e)}',
          type: SnackBarType.error,
        );
      }
    }
  }

  /// 더 많은 물품 로드 (페이징)
  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || !_hasMoreItems || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final itemApi = ItemApi();
      final request = ItemRequest(
        pageNumber: _currentPage + 1,
        pageSize: _pageSize,
        itemStatus: _currentTabStatus.serverName,
      );

      final response = await itemApi.getMyItems(request);
      final newItems = response.itemPage?.content ?? [];

      if (mounted) {
        setState(() {
          _myItems.addAll(newItems);
          _currentPage++;
          _hasMoreItems = newItems.length == _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
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
    // 무한 스크롤 처리
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }

    // 기존 타이머 취소
    _scrollTimer?.cancel();

    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: AppColors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.primaryBlack,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // === 콘텐츠 ===
            SafeArea(
              top: false,
              child: RefreshIndicator(
                color: AppColors.primaryYellow,
                backgroundColor: AppColors.transparent,
                displacement: MediaQuery.of(context).padding.top + 58.h + 62.h,
                onRefresh: () async {
                  try {
                    await _loadMyItems(isRefresh: true);
                  } finally {
                    // 새로고침 완료 후 타이머로 스크롤 상태 업데이트 (0.5초 딜레이)
                    _scrollTimer = Timer(const Duration(milliseconds: 500), () {
                      if (_scrollController.hasClients) {
                        final isNowScrolled = _scrollController.offset > 50;
                        if (isNowScrolled != _isScrolled) {
                          setState(() {
                            _isScrolled = isNowScrolled;
                          });
                        }
                      }
                    });
                  }
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: GlassHeaderDelegate(
                        headerTitle: '나의 등록된 물건',
                        toggle: GlassHeaderToggleBuilder.buildDefaultToggle(
                          animation: _toggleAnimation,
                          isRightSelected: _currentTabStatus == MyItemToggleStatus.completed,
                          onLeftTap: () => _onToggleChanged(MyItemToggleStatus.selling),
                          onRightTap: () => _onToggleChanged(MyItemToggleStatus.completed),
                          leftText: '판매 중',
                          rightText: '교환 완료',
                        ),
                        statusBarHeight: MediaQuery.of(context).padding.top, // ★ 꼭 전달
                        toolbarHeight: 58.h,
                        toggleHeight: 62.h,
                        expandedExtra: 16.h, // 큰 제목/여백
                        enableBlur: _isScrolled, // 스크롤 시 더 진해지게
                      ),
                    ),
                    // 아이템 리스트 슬리버들
                    ..._buildItemSlivers(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItemSlivers() {
    if (_isLoading && _myItems.isEmpty) {
      return const [RegisterTabSkeletonSliver()];
    }

    final filteredItems = _myItems.where((item) {
      return item.itemStatus == _currentTabStatus.serverName;
    }).toList();

    if (filteredItems.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(), // 여기엔 ListView 같은 스크롤 위젯 넣지 않기
        ),
      ];
    }

    // separator interleave: item, divider, item, divider...
    final itemCountWithSeparators = filteredItems.length * 2 - 1;

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(right: 24.w, bottom: 16.h),
          child: Text(
            _currentTabStatus == MyItemToggleStatus.selling
                ? '${filteredItems.length}/10개'
                : '${filteredItems.length}개',
            textAlign: TextAlign.right,
            style: CustomTextStyles.p1.copyWith(color: AppColors.opacity60White, fontWeight: FontWeight.w400),
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index.isOdd) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0.w),
              child: Divider(thickness: 1.5, color: AppColors.opacity10White, height: 32.h),
            );
          }
          final item = filteredItems[index ~/ 2];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0.w),
            child: _buildItemTile(item, index ~/ 2),
          );
        }, childCount: itemCountWithSeparators),
      ),
      if (_hasMoreItems)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: const Center(child: CommonLoadingIndicator()),
          ),
        ),
      // 하단 여백 24px
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
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: SizedBox(
                  width: 90.w,
                  height: 90.w,
                  child: item.itemId != null
                      ? Hero(tag: 'itemImage_${item.itemId}_0', child: _buildImage(imageUrl))
                      : _buildImage(imageUrl),
                ),
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
                    Text(uploadTime, style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White)),
                    SizedBox(height: 12.h),
                    Text('${formatPrice(item.price ?? 0)}원', style: CustomTextStyles.p1),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Icon(AppIcons.itemRegisterHeart, size: 14.sp, color: AppColors.opacity60White),
                        SizedBox(width: 4.w),
                        Text(
                          '${item.likeCount ?? 0}',
                          style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Positioned(
          right: 0,
          bottom: 0,
          child: TradeStatusTagWidget(
            status: item.itemStatus == ItemStatus.exchanged.serverName ? TradeStatus.traded : TradeStatus.pending,
          ),
        ),
      ],
    );
  }

  /// 토글 상태 변경
  void _onToggleChanged(MyItemToggleStatus newStatus) {
    if (_currentTabStatus != newStatus) {
      if (newStatus == MyItemToggleStatus.completed) {
        _toggleAnimationController.forward();
      } else {
        _toggleAnimationController.reverse();
      }

      setState(() {
        _currentTabStatus = newStatus;
      });

      _loadMyItems(isRefresh: true);
    }
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

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailDescriptionScreen(
          itemId: item.itemId!,
          imageSize: Size(MediaQuery.of(context).size.width, 400.h),
          currentImageIndex: 0,
          heroTag: 'itemImage_${item.itemId}_0', // ← 인덱스 포함
          isMyItem: true,
          isRequestManagement: false,
        ),
      ),
    );

    // 상태 변경 또는 삭제 후 목록 새로고침
    if (result == true) {
      _loadMyItems(isRefresh: true);
    }
  }
}
