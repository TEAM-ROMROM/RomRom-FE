import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/apis/responses/item_detail.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/screens/item_register_screen.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/widgets/common/item_options_menu.dart';
import 'dart:async';

import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/time_utils.dart';

class RegisterTabScreen extends StatefulWidget {
  const RegisterTabScreen({super.key});

  @override
  State<RegisterTabScreen> createState() => _RegisterTabScreenState();
}

class _RegisterTabScreenState extends State<RegisterTabScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  bool _isScrolling = false;
  Timer? _scrollTimer;

  // API 상태 관리
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  List<ItemDetail> _myItems = [];
  
  // 페이지네이션
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _hasMoreItems = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadMyItems(); // 초기 데이터 로드
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }

  /// 내 물품 목록 조회 API 호출
  Future<void> _loadMyItems({bool isRefresh = false}) async {
    if (_isLoading || (_isLoadingMore && !isRefresh)) return;

    if (isRefresh) {
      setState(() {
        _currentPage = 0;
        _hasMoreItems = true;
        _myItems.clear();
      });
    }

    setState(() {
      if (isRefresh || _currentPage == 0) {
        _isLoading = true;
        _hasError = false;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final request = ItemRequest(
        pageNumber: _currentPage,
        pageSize: _pageSize,
      );

      final response = await ItemApi().getMyItems(request);
      
      if (!mounted) return;

      final newItems = response.itemDetailPage?.content ?? [];
      final totalElements = response.itemDetailPage?.totalElements ?? 0;
      
      setState(() {
        if (isRefresh || _currentPage == 0) {
          _myItems = newItems;
        } else {
          _myItems.addAll(newItems);
        }
        
        _hasMoreItems = _myItems.length < totalElements;
        _currentPage++;
        _isLoading = false;
        _isLoadingMore = false;
        _hasError = false;
      });

      debugPrint('내 물품 목록 로드 성공: ${_myItems.length}개 (전체: $totalElements개)');
      
    } catch (e) {
      debugPrint('내 물품 목록 조회 실패: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _hasError = true;
        _errorMessage = '물품 목록을 불러올 수 없습니다.';
      });
    }
  }

  void _scrollListener() {
    // 스크롤 중임을 표시
    setState(() {
      _isScrolling = true;
    });

    // 기존 타이머 취소
    _scrollTimer?.cancel();

    // 스크롤이 멈춘 후 0.7초 후에 스크롤이 끝났다고 판단
    _scrollTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _isScrolling = false;
        });
      }
    });

    // 헤더 스크롤 상태 업데이트
    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }

    // 무한 스크롤 처리
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMoreItems && !_isLoadingMore) {
        _loadMyItems();
      }
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
                  expandedHeight: 120.h,
                  toolbarHeight: 58.h,
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
                        padding: EdgeInsets.fromLTRB(24.w, 56.h, 24.w, 40.h),
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
              ],
              body: RefreshIndicator(
                onRefresh: () => _loadMyItems(isRefresh: true),
                child: _buildContent(),
              ),
            ),
          ),
          _buildRegisterFabStacked(context),
        ],
      ),
    );
  }

  /// 메인 콘텐츠 빌드
  Widget _buildContent() {
    if (_isLoading && _myItems.isEmpty) {
      return _buildLoadingState();
    }

    if (_hasError && _myItems.isEmpty) {
      return _buildErrorState();
    }

    if (_myItems.isEmpty) {
      return _buildEmptyState();
    }

    return _buildItemsList();
  }

  /// 로딩 상태 UI
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryYellow,
      ),
    );
  }

  /// 에러 상태 UI
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: AppColors.opacity60White,
            ),
            SizedBox(height: 16.h),
            Text(
              _errorMessage,
              style: CustomTextStyles.p1.copyWith(
                color: AppColors.opacity60White,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => _loadMyItems(isRefresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: AppColors.primaryBlack,
              ),
              child: Text(
                '다시 시도',
                style: CustomTextStyles.p1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 빈 상태 UI
  Widget _buildEmptyState() {
    return Center(
      child: Text(
        '등록된 물건이 없습니다',
        style: CustomTextStyles.p1.copyWith(
          color: AppColors.opacity60White,
        ),
      ),
    );
  }

  /// 물품 목록 UI
  Widget _buildItemsList() {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        bottom: _isLoadingMore ? 80.h : 0,
      ),
      itemCount: _myItems.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _myItems.length) {
          // 로딩 더 보기 인디케이터
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryYellow,
                strokeWidth: 2,
              ),
            ),
          );
        }
        
        return _buildItemTile(_myItems[index], index);
      },
      separatorBuilder: (context, index) => Divider(
        thickness: 1.5,
        color: AppColors.opacity10White,
        height: 32.h,
      ),
    );
  }

  /// 개별 물품 타일 UI
  Widget _buildItemTile(ItemDetail item, int index) {
    return SizedBox(
      height: 90.h,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 이미지 썸네일
              _buildItemImage(item),
              SizedBox(width: 16.w),
              // 텍스트 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.itemName ?? '제목 없음',
                      style: CustomTextStyles.p1
                          .copyWith(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      TimeUtils.formatRelativeTime(item.createdDate),
                      style: CustomTextStyles.p2.copyWith(
                        color: AppColors.opacity60White,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    if (item.price != null)
                      Text(
                        '${formatPrice(item.price!)}원',
                        style: CustomTextStyles.p1,
                      ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Icon(AppIcons.itemRegisterHeart,
                            size: 14.sp, color: AppColors.opacity60White),
                        SizedBox(width: 4.w),
                        Text(
                          '${item.likeCount ?? 0}',
                          style: CustomTextStyles.p2.copyWith(
                            color: AppColors.opacity60White,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 30.w), // 더보기 버튼 공간
            ],
          ),
          // 우측 상단 더보기 버튼
          Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 30.w,
              height: 30.h,
              child: ItemOptionsMenuButton(
                onEditPressed: () {
                  debugPrint('${item.itemName} 수정 버튼 클릭');
                  // TODO: 수정 기능 구현
                },
                onDeletePressed: () async {
                  final result = await context.showWarningDialog(
                    title: '물건을 삭제하시겠습니까?',
                    description: '삭제된 물건은 복구할 수 없습니다.',
                  );

                  if (result == true) {
                    debugPrint('${item.itemName} 삭제 확인');
                    // TODO: 삭제 API 호출 및 목록 새로고침
                    await _loadMyItems(isRefresh: true);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 물품 이미지 빌드 (ErrorImagePlaceholder 사용)
  Widget _buildItemImage(ItemDetail item) {
    final imageUrl = item.itemImageUrls?.isNotEmpty == true 
        ? item.itemImageUrls!.first 
        : null;

    return Container(
      width: 90.w,
      height: 90.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.r),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
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
              )
            : const ErrorImagePlaceholder(),
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
                      if (mounted) {
                        await _loadMyItems(isRefresh: true);
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
}
