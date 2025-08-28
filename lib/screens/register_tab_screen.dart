import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/item_modification_screen.dart';
import 'package:romrom_fe/screens/item_register_screen.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/widgets/common/item_options_menu.dart';
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
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: null,
      body: Stack(
        children: [
          SafeArea(
            child: NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppColors.primaryBlack,
                  expandedHeight:
                      88.h, // 32px(상단) + 32px(제목높이) + 24px(하단) = 88px
                  toolbarHeight:
                      58.h, // 16px(상단) + 18px(제목높이) + 24px(하단) = 58px
                  titleSpacing: 0,
                  elevation: innerBoxIsScrolled || _isScrolled ? 0.5 : 0,
                  automaticallyImplyLeading: false,
                  title: Padding(
                    padding: EdgeInsets.only(top: 16.h, bottom: 24.h),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: innerBoxIsScrolled || _isScrolled ? 1.0 : 0.0,
                      child: Text(
                        '나의 등록된 물건',
                        style: CustomTextStyles.h3
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  centerTitle: true,
                  flexibleSpace: Container(
                    color: AppColors.primaryBlack,
                    child: FlexibleSpaceBar(
                      background: Padding(
                        padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w,
                            24.h), // 좌측 24px, 상단 32px, 우측 24px, 하단 24px
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity:
                                innerBoxIsScrolled || _isScrolled ? 0.0 : 1.0,
                            child: Text(
                              '나의 등록된 물건',
                              style: CustomTextStyles.h1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 토글 위젯을 고정 헤더로 추가
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ToggleHeaderDelegate(
                    child: _buildToggleWidget(),
                  ),
                ),
              ],
              body: _buildItemsList(), // 토글 위젯 제거
            ),
          ),
          _buildRegisterFabStacked(context),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (_isLoading && _myItems.isEmpty) {
      // 초기 로딩 시 스켈레톤 보여주기
      return const RegisterTabSkeleton();
    }

    if (_myItems.isEmpty) {
      // 데이터가 없을 때 빈 상태 보여주기
      return _buildEmptyState();
    }

    final totalItemCount = _myItems.length + (_hasMoreItems ? 1 : 0);

    return RefreshIndicator(
      color: AppColors.primaryYellow,
      backgroundColor: AppColors.primaryBlack,
      onRefresh: () => _loadMyItems(isRefresh: true),
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        itemCount: totalItemCount,
        itemBuilder: (context, index) {
          if (index < _myItems.length) {
            return _buildItemTile(_myItems[index], index);
          } else {
            // 로딩 인디케이터
            return _buildLoadingIndicator();
          }
        },
        separatorBuilder: (context, index) => Divider(
          thickness: 1.5,
          color: AppColors.opacity10White,
          height: 32.h,
        ),
      ),
    );
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

  /// 로딩 인디케이터
  Widget _buildLoadingIndicator() {
    return Padding(
      padding: EdgeInsets.all(16.h),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryYellow,
        ),
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
              child: ItemOptionsMenuButton(
                onEditPressed: () => _navigateToEditItem(item),
                onDeletePressed: () => _showDeleteConfirmDialog(item),
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
          color: AppColors.secondaryBlack, // #34353D
        ),
        child: Stack(
          children: [
            // 애니메이션 선택된 배경
            AnimatedBuilder(
              animation: _toggleAnimation,
              builder: (context, child) {
                return Positioned(
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
                );
              },
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
                      child: Text(
                        '판매 중',
                        style: CustomTextStyles.p1.copyWith(
                          color: !_isCompletedSelected
                              ? AppColors.textColorWhite
                              : AppColors.opacity60White,
                          fontWeight: FontWeight.w500,
                        ),
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
                      child: Text(
                        '거래 완료',
                        style: CustomTextStyles.p1.copyWith(
                          color: _isCompletedSelected
                              ? AppColors.textColorWhite
                              : AppColors.opacity60White,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 토글 상태 변경
  void _onToggleChanged(bool isCompleted) {
    if (_isCompletedSelected != isCompleted) {
      setState(() {
        _isCompletedSelected = isCompleted;
      });

      if (isCompleted) {
        _toggleAnimationController.forward();
      } else {
        _toggleAnimationController.reverse();
      }

      // API 재요청 (필터링)
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
          heroTag: 'register_item_${item.itemId}',
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
    final result = await context.showWarningDialog(
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

/// 토글 위젯을 고정하기 위한 SliverPersistentHeaderDelegate
class _ToggleHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _ToggleHeaderDelegate({required this.child});

  @override
  double get minExtent => 70.h; // 토글 위젯 높이 + 패딩 (46h + 24h)

  @override
  double get maxExtent => 70.h;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.primaryBlack,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
