import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/enums/my_item_toggle_status.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/item_modification_screen.dart';
import 'package:romrom_fe/screens/item_register_screen.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/screens/home_tab_screen.dart';
import 'package:romrom_fe/widgets/common/romrom_context_menu.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/widgets/skeletons/register_tab_skeleton.dart';
import 'package:romrom_fe/widgets/common/glass_header_delegate.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'dart:async';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';

import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/screens/main_screen.dart';

class RegisterTabScreen extends StatefulWidget {
  const RegisterTabScreen({super.key});

  @override
  State<RegisterTabScreen> createState() => _RegisterTabScreenState();
}

class _RegisterTabScreenState extends State<RegisterTabScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false; //
  bool _isScrolling = false;
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
    _toggleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _toggleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _toggleAnimationController,
      curve: Curves.easeInOut,
    ));

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
    debugPrint(
        '_loadMyItems 호출됨: isRefresh=$isRefresh, _isLoading=$_isLoading');

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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('내 물품 목록 로드 실패: ${ErrorUtils.getErrorMessage(e)}'),
            backgroundColor: AppColors.warningRed,
          ),
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('추가 물품 로드 실패: ${ErrorUtils.getErrorMessage(e)}'),
            backgroundColor: AppColors.warningRed,
          ),
        );
      }
    }
  }

  /// 첫 물건 등록 후 홈탭으로 전환하고 상세 페이지로 이동
  void _navigateToHomeAndShowDetail(String itemId) {
    debugPrint('====================================');
    debugPrint('_navigateToHomeAndShowDetail 호출됨: itemId=$itemId');
    
    // MainScreen의 GlobalKey를 통해 홈탭(인덱스 0)으로 전환
    final mainState = MainScreen.globalKey.currentState;
    debugPrint('MainScreen.globalKey.currentState: $mainState');
    
    if (mainState != null) {
      debugPrint('홈 탭(인덱스 0)으로 전환 시도...');
      (mainState as dynamic).switchToTab(0);
    } else {
      debugPrint('⚠️ MainScreen.globalKey.currentState가 null입니다!');
    }

    // 탭 전환 후 홈탭의 context에서 상세 페이지로 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeState = HomeTabScreen.globalKey.currentState;
      debugPrint('HomeTabScreen.globalKey.currentState: $homeState');
      
      if (homeState != null) {
        debugPrint('HomeTabScreen의 navigateToItemDetail 호출 시도...');
        // _HomeTabScreenState의 navigateToItemDetail 메서드 호출
        (homeState as dynamic).navigateToItemDetail(itemId);
      } else {
        debugPrint('⚠️ HomeTabScreen.globalKey.currentState가 null입니다!');
      }
    });
    debugPrint('====================================');
  }

  void _scrollListener() {
    // 무한 스크롤 처리
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }

    // 스크롤 중임을 표시
    setState(() {
      _isScrolling = true;
    });

    // 기존 타이머 취소
    _scrollTimer?.cancel();

    // 스크롤이 멈춘 후 0.3초 후에 스크롤이 끝났다고 판단
    _scrollTimer = Timer(const Duration(milliseconds: 700), () {
      setState(() {
        _isScrolling = false;
      });
    });

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
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: AppColors.transparent),
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
                onRefresh: () => _loadMyItems(isRefresh: true),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
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
                          rightText: '거래 완료',
                        ),
                        statusBarHeight:
                            MediaQuery.of(context).padding.top, // ★ 꼭 전달
                        toolbarHeight: 58.h,
                        toggleHeight: 70.h,
                        expandedExtra: 32.h, // 큰 제목/여백
                        enableBlur: _isScrolled, // 스크롤 시 더 진해지게
                      ),
                    ),

                    // 아이템 리스트 슬리버들
                    ..._buildItemSlivers(),
                  ],
                ),
              ),
            ),

            // FAB 등
            _buildRegisterFabStacked(context),
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
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index.isOdd) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0.w),
                child: Divider(
                  thickness: 1.5,
                  color: AppColors.opacity10White,
                  height: 32.h,
                ),
              );
            }
            final item = filteredItems[index ~/ 2];
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0.w),
              child: _buildItemTile(item, index ~/ 2),
            );
          },
          childCount: itemCountWithSeparators,
        ),
      ),
      if (_hasMoreItems)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      // 하단 여백 24px
      SliverToBoxAdapter(
        child: SizedBox(height: 24.h),
      ),
    ];
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    return Center(
      child: Text(
        '등록된 물건이 없어요.',
        style: CustomTextStyles.p1.copyWith(
          color: AppColors.opacity40White,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 실제 데이터 아이템 타일
  Widget _buildItemTile(Item item, int index) {
    final imageUrl = item.primaryImageUrl != null
        ? item.primaryImageUrl!
        : 'https://picsum.photos/400/300';

    final uploadTime =
        item.createdDate != null ? getTimeAgo(item.createdDate!) : 'Unknown';

    return SizedBox(
      height: 90.h,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _navigateToItemDetail(item),
            behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 이미지 썸네일
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: SizedBox(
                    width: 90.w,
                    height: 90.h,
                    child: item.itemId != null
                        ? Hero(
                            tag: 'itemImage_${item.itemId}_0',
                            child: _buildImage(imageUrl),
                          )
                        : _buildImage(imageUrl),
                  ),
                ),
                SizedBox(width: 16.h),

                // 텍스트 영역
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.itemName ?? '물품명 없음',
                        style: CustomTextStyles.p1
                            .copyWith(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        uploadTime,
                        style: CustomTextStyles.p2
                            .copyWith(color: AppColors.opacity60White),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        '${formatPrice(item.price ?? 0)}원',
                        style: CustomTextStyles.p1,
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Icon(
                            AppIcons.itemRegisterHeart,
                            size: 14.sp,
                            color: AppColors.opacity60White,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${item.likeCount ?? 0}',
                            style: CustomTextStyles.p2
                                .copyWith(color: AppColors.opacity60White),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 30.w),
              ],
            ),
          ),

          // 더보기 버튼
          Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 30.w,
              height: 30.h,
              child: RomRomContextMenu(
                items: [
                  ContextMenuItem(
                    id: 'changeTradeStatus',
                    title: _currentTabStatus == MyItemToggleStatus.selling 
                        ? '거래완료로 변경' 
                        : '판매중으로 변경',
                    onTap: () => _showChangeStatusConfirmDialog(item),
                    showDividerAfter: true,
                  ),
                  ContextMenuItem(
                    id: 'edit',
                    title: '수정',
                    onTap: () => _navigateToEditItem(item),
                    showDividerAfter: true,
                  ),
                  ContextMenuItem(
                    id: 'delete',
                    title: '삭제',
                    textColor: AppColors.itemOptionsMenuDeleteText,
                    onTap: () => _showDeleteConfirmDialog(item),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 등록하기 fab 버튼
  Widget _buildRegisterFabStacked(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 32.h,
      child: IgnorePointer(
        ignoring: _isScrolling,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: _isScrolling ? 0.0 : 1.0,
          curve: Curves.easeInOut,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isScrolling ? 0.0 : 1.0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(100.r),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.opacity20Black,
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(100.r),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ItemRegisterScreen(
                            onClose: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );

                      debugPrint('====================================');
                      debugPrint('ItemRegisterScreen에서 돌아옴: result=$result');
                      debugPrint('result type: ${result.runtimeType}');
                      if (result is Map<String, dynamic>) {
                        debugPrint('  - isFirstItemPosted: ${result['isFirstItemPosted']}');
                        debugPrint('  - itemId: ${result['itemId']}');
                      }
                      debugPrint('====================================');

                      // 등록 화면에서 돌아온 뒤 목록 새로고침
                      _loadMyItems(isRefresh: true);

                      // 첫 물건 등록 완료 시 홈탭으로 전환 후 상세 페이지로 이동
                      if (result is Map<String, dynamic> &&
                          result['isFirstItemPosted'] == true &&
                          result['itemId'] != null) {
                        debugPrint('첫 물건 등록 확인! 홈 탭으로 이동 시작...');
                        _navigateToHomeAndShowDetail(result['itemId'] as String);
                      } else {
                        debugPrint('첫 물건 등록 조건 불충족: isFirstItemPosted=${result is Map ? result['isFirstItemPosted'] : 'N/A'}, itemId=${result is Map ? result['itemId'] : 'N/A'}');
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 18.w, vertical: 15.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.addItemPlus,
                            size: 16.sp,
                            color: AppColors.primaryBlack,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '등록하기',
                            style: CustomTextStyles.h3.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textColorBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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

    return Image.network(
      imageUrl.trim(),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('RegisterTab 이미지 로드 실패: $imageUrl, error: $error');
        return const ErrorImagePlaceholder();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppColors.opacity20White,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryYellow,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
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

  /// 물품 수정 화면으로 이동
  Future<void> _navigateToEditItem(Item item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemModificationScreen(
          itemId: item.itemId,
          onClose: () {
            Navigator.pop(context);
          },
        ),
      ),
    );

    // 수정 완료 후 목록 새로고침
    if (result == true) {
      _loadMyItems(isRefresh: true);
    }
  }

  /// 상태 변경 확인 대화상자
  Future<void> _showChangeStatusConfirmDialog(Item item) async {
    final isToCompleted = _currentTabStatus == MyItemToggleStatus.selling;
    final title = isToCompleted 
        ? '거래 완료로 변경하시겠습니까?' 
        : '판매중으로 변경하시겠습니까?';
    final description = isToCompleted 
        ? '거래완료로 변경하시겠습니까?' 
        : '판매중으로 변경하시겠습니까?';

    final result = await context.showDeleteDialog(
      title: title,
      description: description,
    );

    if (result == true) {
      await _toggleItemStatus(item);
    }
  }

  /// 삭제 확인 대화상자
  Future<void> _showDeleteConfirmDialog(Item item) async {
    final result = await context.showDeleteDialog(
      title: '물품을 삭제하시겠습니까?',
      description: '삭제된 물품은 복구할 수 없습니다.',
    );

    if (result == true) {
      await _deleteItem(item);
    }
  }

  /// 물품 상태 토글
  Future<void> _toggleItemStatus(Item item) async {
    if (item.itemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('물품 ID가 없습니다'),
          backgroundColor: AppColors.warningRed,
        ),
      );
      return;
    }

    try {
      final itemApi = ItemApi();
      final targetStatus = _currentTabStatus == MyItemToggleStatus.selling
          ? ItemStatus.exchanged.serverName
          : ItemStatus.available.serverName;
      
      final request = ItemRequest(
        itemId: item.itemId,
        itemStatus: targetStatus,
      );
      
      await itemApi.updateItemStatus(request);

      // 성공 시 목록 새로고침
      _loadMyItems(isRefresh: true);

      if (mounted) {
        final successMessage = _currentTabStatus == MyItemToggleStatus.selling
            ? '거래 완료로 변경되었습니다'
            : '판매중으로 변경되었습니다';
            
        CommonSnackBar.show(
          context: context,
          message: successMessage,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('상태 변경 실패: ${ErrorUtils.getErrorMessage(e)}'),
            backgroundColor: AppColors.warningRed,
          ),
        );
      }
    }
  }

  /// 물품 삭제
  Future<void> _deleteItem(Item item) async {
    if (item.itemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('물품 ID가 없습니다'),
          backgroundColor: AppColors.warningRed,
        ),
      );
      return;
    }

    try {
      final itemApi = ItemApi();
      await itemApi.deleteItem(item.itemId!);

      // 성공 시 로컬 목록에서 제거
      setState(() {
        _myItems.removeWhere((element) => element.itemId == item.itemId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('물품이 삭제되었습니다'),
            backgroundColor: AppColors.primaryYellow,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('물품 삭제 실패: ${ErrorUtils.getErrorMessage(e)}'),
            backgroundColor: AppColors.warningRed,
          ),
        );
      }
    }
  }
}
