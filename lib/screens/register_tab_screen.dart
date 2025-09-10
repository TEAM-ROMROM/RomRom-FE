import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/item_modification_screen.dart';
import 'package:romrom_fe/screens/item_register_screen.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/widgets/common/romrom_context_menu.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/widgets/skeletons/register_tab_skeleton.dart';
import 'dart:async';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/responses/item_detail.dart';

import 'package:romrom_fe/utils/error_utils.dart';

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
  final List<ItemDetail> _myItems = [];
  int _currentPage = 0;
  final int _pageSize = 20;

  // 토글 상태 (false: 판매 중, true: 거래 완료)
  bool _isCompletedSelected = false;
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
        // TODO: 백엔드에서 거래상태 필터링 지원 시 추가
        // tradeStatus: _isCompletedSelected ? 'COMPLETED' : 'SELLING',
      );

      final response = await itemApi.getMyItems(request);
      final newItems = response.itemDetailPage?.content ?? [];

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
        // TODO: 백엔드에서 거래상태 필터링 지원 시 추가
        // tradeStatus: _isCompletedSelected ? 'COMPLETED' : 'SELLING',
      );

      final response = await itemApi.getMyItems(request);
      final newItems = response.itemDetailPage?.content ?? [];

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
          .copyWith(statusBarColor: Colors.transparent),
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
                        toggle: _buildToggleWidget(),
                        statusBarHeight:
                            MediaQuery.of(context).padding.top, // ★ 꼭 전달
                        toolbarHeight: 58.h,
                        toggleHeight: 70.h,
                        expandedExtra: 32.h, // 큰 제목/여백
                        tintBase: AppColors.primaryBlack,
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
      return true; // TODO: 필터 로직
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
  Widget _buildItemTile(ItemDetail item, int index) {
    final imageUrl = item.itemImageUrls?.isNotEmpty == true
        ? item.itemImageUrls!.first
        : null;
    final uploadTime = _formatUploadTime(item.createdDate);

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
                            tag: 'register_item_${item.itemId}',
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
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ItemRegisterScreen(
                            onClose: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                      // 등록 화면에서 돌아온 뒤 목록 새로고침
                      _loadMyItems(isRefresh: true);
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

  /// 토글 위젯 (판매 중 / 거래 완료)
  Widget _buildToggleWidget() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h), // 상단 패딩 제거, 하단만 24px
      child: Container(
        width: 345.w,
        height: 46.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          color: AppColors.secondaryBlack, // #2C2D36
        ),
        child: AnimatedBuilder(
          animation: _toggleAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                // 애니메이션 선택된 배경
                Positioned(
                  left: 2.w +
                      (_toggleAnimation.value * 171.w), // 2px + 170px + 1px gap
                  top: 2.h,
                  child: Container(
                    width: 170.w,
                    height: 42.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      color: AppColors.primaryBlack, // #1D1E27
                    ),
                  ),
                ),
                // 텍스트 버튼들
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onToggleChanged(false),
                        child: Container(
                          height: 46.h,
                          color: Colors.transparent,
                          alignment: Alignment.center,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: CustomTextStyles.p1.copyWith(
                              color: !_isCompletedSelected
                                  ? AppColors.textColorWhite
                                  : AppColors.opacity60White,
                              fontWeight: FontWeight.w500,
                            ),
                            child: const Text('판매 중'),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onToggleChanged(true),
                        child: Container(
                          height: 46.h,
                          color: Colors.transparent,
                          alignment: Alignment.center,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: CustomTextStyles.p1.copyWith(
                              color: _isCompletedSelected
                                  ? AppColors.textColorWhite
                                  : AppColors.opacity60White,
                              fontWeight: FontWeight.w500,
                            ),
                            child: const Text('거래 완료'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 토글 상태 변경
  void _onToggleChanged(bool isCompleted) {
    if (_isCompletedSelected != isCompleted) {
      if (isCompleted) {
        _toggleAnimationController.forward();
      } else {
        _toggleAnimationController.reverse();
      }

      setState(() {
        _isCompletedSelected = isCompleted;
      });

      // 클라이언트 사이드 필터링 (백엔드 필터링 미지원)
      // TODO: 백엔드에서 거래상태 필터링 지원 시 API 재요청으로 변경
      // _loadMyItems(isRefresh: true);
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

  /// 업로드 시간 포맷팅
  String _formatUploadTime(String? createdDate) {
    if (createdDate == null || createdDate.isEmpty) {
      return '시간 없음';
    }

    try {
      final uploadDate = DateTime.parse(createdDate);
      final now = DateTime.now();
      final difference = now.difference(uploadDate);

      if (difference.inDays > 0) {
        return '${difference.inDays}일 전';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}시간 전';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}분 전';
      } else {
        return '방금 전';
      }
    } catch (e) {
      debugPrint('날짜 파싱 오류: $e');
      return '시간 없음';
    }
  }

  /// 물품 상세 화면으로 이동
  Future<void> _navigateToItemDetail(ItemDetail item) async {
    if (item.itemId == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailDescriptionScreen(
          itemId: item.itemId!,
          imageSize: Size(MediaQuery.of(context).size.width, 400.h),
          currentImageIndex: 0,
          heroTag: 'itemImage_${item.itemId}_0', // ← 인덱스 포함
        ),
      ),
    );
  }

  /// 물품 수정 화면으로 이동
  Future<void> _navigateToEditItem(ItemDetail item) async {
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

  /// 삭제 확인 대화상자
  Future<void> _showDeleteConfirmDialog(ItemDetail item) async {
    final result = await context.showDeleteDialog(
      title: '물품을 삭제하시겠습니까?',
      description: '삭제된 물품은 복구할 수 없습니다.',
    );

    if (result == true) {
      await _deleteItem(item);
    }
  }

  /// 물품 삭제
  Future<void> _deleteItem(ItemDetail item) async {
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

class GlassHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget toggle;
  final double statusBarHeight;
  final double toolbarHeight; // 58.h
  final double toggleHeight; // 70.h
  final double expandedExtra; // 큰 제목/여백 등 “펼침 전용” 추가 높이
  final Color tintBase;
  final bool enableBlur;

  GlassHeaderDelegate({
    required this.toggle,
    required this.statusBarHeight,
    required this.toolbarHeight,
    required this.toggleHeight,
    this.expandedExtra = 32.0, // 큰 제목 여백 등 (원하는 만큼)
    this.tintBase = Colors.black,
    this.enableBlur = true,
  }) : assert(statusBarHeight >= 0 && toolbarHeight >= 0 && toggleHeight >= 0);

  // ⬇️ 토글을 포함해서 최소 높이를 정의 → 토글이 항상 보임
  @override
  double get minExtent => statusBarHeight + toolbarHeight + toggleHeight;

  // ⬇️ 펼쳐질 때만 추가로 커지는 영역(큰 제목 등)
  @override
  double get maxExtent => minExtent + expandedExtra;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final extraRange = (maxExtent - minExtent).clamp(0.0, double.infinity);
    final t =
        extraRange == 0 ? 1.0 : (shrinkOffset / extraRange).clamp(0.0, 1.0);

    final sigma = enableBlur ? lerpDouble(0, 30, t)! : 0.0;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1) 블러
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: const SizedBox.expand(),
          ),

          // 2) 틴트(사파리 감성은 그라데이션 추천)
          Container(
            decoration: const BoxDecoration(
              color: AppColors.opacity90PrimaryBlack,
            ),
          ),

          // 3) 큰 제목(펼침에서만 보이고 스크롤되면 사라짐)
          Positioned(
            left: 24,
            right: 24,
            top: statusBarHeight + 32,
            child: Opacity(
              opacity: 1.0 - t,
              child: Text('나의 등록된 물건', style: CustomTextStyles.h1),
            ),
          ),

          // 4) 작은 제목(툴바 타이틀 역할) — 스크롤될수록 나타남
          Positioned(
            left: 0,
            right: 0,
            top: statusBarHeight,
            height: toolbarHeight,
            child: IgnorePointer(
              ignoring: true,
              child: Center(
                child: Opacity(
                  opacity: t,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 24),
                    child: Text(
                      '나의 등록된 물건',
                      style: CustomTextStyles.h3
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 5) 🔒 토글: 항상 보이는 영역(최소 높이에 포함시켰기 때문에 사라지지 않음)
          Positioned(
            left: 0,
            right: 0,
            top: statusBarHeight + toolbarHeight + lerpDouble(24, 0, t)!,
            height: toggleHeight,
            child: Material(
              color: Colors.transparent,
              child: toggle,
            ),
          ),

          // 6) 하단 라인(살짝)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.15 * t,
              child: const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.opacity20Black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant GlassHeaderDelegate old) {
    return toggle != old.toggle ||
        statusBarHeight != old.statusBarHeight ||
        toolbarHeight != old.toolbarHeight ||
        toggleHeight != old.toggleHeight ||
        expandedExtra != old.expandedExtra ||
        enableBlur != old.enableBlur ||
        tintBase != old.tintBase;
  }
}
