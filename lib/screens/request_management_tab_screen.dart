import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';

import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/request_management_item_card.dart';
import 'package:romrom_fe/widgets/common/completed_toggle_switch.dart';
import 'package:romrom_fe/widgets/common/trade_status_tag.dart';
import 'package:romrom_fe/widgets/request_list_item_card_widget.dart';
import 'package:romrom_fe/widgets/request_management_item_card_widget.dart';

class RequestManagementTabScreen extends StatefulWidget {
  const RequestManagementTabScreen({super.key});

  @override
  State<RequestManagementTabScreen> createState() =>
      _RequestManagementTabScreenState();
}

class _RequestManagementTabScreenState extends State<RequestManagementTabScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  
  // 스크롤 상태 관리
  bool _isScrolled = false;

  // 현재 선택된 카드 인덱스
  int _currentCardIndex = 0;
  
  // 카드 컨트롤러
  late PageController _cardController;
  
  // 토글 애니메이션 컨트롤러
  late AnimationController _toggleAnimationController;
  late Animation<double> _toggleAnimation;

  // 토글 상태 (false: 받은 요청, true: 보낸 요청)
  bool _isRightSelected = false;
  
  // 완료된 요청 표시 여부
  bool _showCompletedRequests = false;
  
  // 테스트용 샘플 데이터
  final List<RequestManagementItemCard> _itemCards = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    
    // 카드 컨트롤러 초기화
    _cardController = PageController(
      initialPage: 0,
      viewportFraction: 0.6, // 화면에 보이는 카드의 비율
    );
    
    // 토글 애니메이션 컨트롤러 초기화
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
    
    // 테스트용 샘플 데이터 생성
    _loadSampleData();
  }

  void _loadSampleData() {
    setState(() {
      _itemCards.addAll([
        RequestManagementItemCard(
          imageUrl: 'https://picsum.photos/200/300?random=1',
          category: '스포츠/레저',
          title: '나이키 에어맥스 270',
          price: 85000,
          likeCount: 12,
          isAiAnalyzed: true,
        ),
        RequestManagementItemCard(
          imageUrl: 'https://picsum.photos/200/300?random=2',
          category: '전자기기',
          title: '애플워치 7세대 44mm',
          price: 320000,
          likeCount: 25,
          isAiAnalyzed: false,
        ),
        RequestManagementItemCard(
          imageUrl: 'https://picsum.photos/200/300?random=3',
          category: '패션/의류',
          title: '노스페이스 패딩 자켓',
          price: 150000,
          likeCount: 8,
          isAiAnalyzed: true,
        ),
      ]);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _scrollTimer?.cancel();
    _cardController.dispose();
    _toggleAnimationController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // 스크롤 타이머 리셋
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 100), () {
      // 스크롤이 멈췄을 때의 처리
    });
    
    // 스크롤 상태 감지
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

  void _onToggleChanged(bool isRightSelected) {
    setState(() {
      _isRightSelected = isRightSelected;
      if (isRightSelected) {
        _toggleAnimationController.forward();
      } else {
        _toggleAnimationController.reverse();
      }
    });
  }

  void _toggleCompletedRequests(bool value) {
    setState(() {
      _showCompletedRequests = value;
    });
  }

  void _onCardPageChanged(int index) {
    setState(() {
      _currentCardIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.primaryBlack,
              expandedHeight: 88.h,
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
                    '요청 관리',
                    style: CustomTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              centerTitle: true,
              flexibleSpace: Container(
                color: AppColors.primaryBlack,
                child: FlexibleSpaceBar(
                  background: Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: innerBoxIsScrolled || _isScrolled ? 0.0 : 1.0,
                        child: Text(
                          '요청 관리',
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
                child: _buildToggleSelector(),
              ),
            ),
          ],
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10.h),

                // 1. 물품 카드 캐러셀 섹션
                _buildItemCardsCarousel(),
                
                // 2. 페이지 인디케이터
                _buildPageIndicator(),
                
                // 3. 요청 목록 헤더 섹션 (제목 + 필터 토글)
                _buildRequestListHeader(),
                
                // 4. 요청 목록 리스트
                _buildFullRequestItemsList(),
                
                SizedBox(height: 100.h), // 하단 여백
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 토글 셀렉터 구현
  Widget _buildToggleSelector() {
    return Container(
      color: AppColors.primaryBlack,
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
      child: Container(
        width: 345.w,
        height: 46.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          color: AppColors.secondaryBlack,
        ),
        child: Stack(
          children: [
            // 애니메이션 선택된 배경
            AnimatedBuilder(
              animation: _toggleAnimation,
              builder: (context, child) {
                return Positioned(
                  left: 2.w + (_toggleAnimation.value * 171.w),
                  top: 2.h,
                  child: Container(
                    width: 170.w,
                    height: 42.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      color: AppColors.primaryBlack,
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
                        '받은 요청',
                        style: CustomTextStyles.p1.copyWith(
                          color: !_isRightSelected
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
                        '보낸 요청',
                        style: CustomTextStyles.p1.copyWith(
                          color: _isRightSelected
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

  /// 물품 카드 캐러셀 섹션
  Widget _buildItemCardsCarousel() {
    if (_itemCards.isEmpty) {
      // 데이터가 없을 때 빈 상태 표시
      return Container(
        height: 326.h,
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Center(
          child: Text(
            '등록된 물품이 없습니다',
            style: CustomTextStyles.p2.copyWith(
              color: AppColors.opacity60White,
            ),
          ),
        ),
      );
    }
    
    return SizedBox(
      height: 326.h,
      child: PageView.builder(
        controller: _cardController,
        onPageChanged: _onCardPageChanged,
        itemCount: _itemCards.length,
        itemBuilder: (context, index) {
          return RequestManagementItemCardWidget(
            card: _itemCards[index],
            isActive: index == _currentCardIndex,
          );
        },
      ),
    );
  }

  /// 페이지 인디케이터
  Widget _buildPageIndicator() {
    if (_itemCards.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 37.h, 0, 32.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _itemCards.length,
          (index) => Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            width: 8.w,
            height: 8.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentCardIndex == index
                  ? AppColors.primaryYellow
                  : AppColors.opacity30White,
            ),
          ),
        ),
      ),
    );
  }

  /// 요청 목록 헤더 섹션
  Widget _buildRequestListHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _isRightSelected ? '보낸 요청 목록' : '받은 요청 목록',
            style: CustomTextStyles.h2,
          ),
          CompletedToggleSwitch(
            value: _showCompletedRequests,
            onChanged: _toggleCompletedRequests,
          ),
        ],
      ),
    );
  }

  /// 요청 목록 리스트
  Widget _buildFullRequestItemsList() {
    // 테스트용 샘플 데이터
    final List<Map<String, dynamic>> sampleRequests = [
      {
        'imageUrl': 'https://picsum.photos/100/100?random=4',
        'title': '나이키 에어맥스 270 구매 요청',
        'address': '강남구',
        'createdDate': DateTime.now().subtract(const Duration(hours: 2)),
        'isNew': true,
        'tradeOptions': [ItemTradeOption.directOnly],
        'tradeStatus': TradeStatus.chatting,
      },
      {
        'imageUrl': 'https://picsum.photos/100/100?random=5',
        'title': '애플워치 7세대 교환 요청',
        'address': '서초구',
        'createdDate': DateTime.now().subtract(const Duration(days: 1)),
        'isNew': false,
        'tradeOptions': [ItemTradeOption.deliveryOnly],
        'tradeStatus': TradeStatus.completed,
      },
      {
        'imageUrl': 'https://picsum.photos/100/100?random=6',
        'title': '노스페이스 패딩 판매 요청',
        'address': '송파구',
        'createdDate': DateTime.now().subtract(const Duration(days: 2)),
        'isNew': false,
        'tradeOptions': [ItemTradeOption.directOnly, ItemTradeOption.extraCharge],
        'tradeStatus': TradeStatus.chatting,
      },
    ];

    // 완료 여부에 따른 필터링
    final filteredRequests = sampleRequests.where((request) {
      final status = request['tradeStatus'] as TradeStatus;
      if (_showCompletedRequests) {
        return status == TradeStatus.completed;
      } else {
        return status != TradeStatus.completed;
      }
    }).toList();

    if (filteredRequests.isEmpty) {
      return Container(
        height: 200.h,
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Center(
          child: Text(
            _showCompletedRequests ? '완료된 요청이 없습니다' : '진행 중인 요청이 없습니다',
            style: CustomTextStyles.p2.copyWith(
              color: AppColors.opacity60White,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: filteredRequests.map((request) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: RequestListItemCardWidget(
              imageUrl: request['imageUrl'],
              title: request['title'],
              address: request['address'],
              createdDate: request['createdDate'],
              isNew: request['isNew'],
              tradeOptions: request['tradeOptions'],
              tradeStatus: request['tradeStatus'],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 토글 헤더 delegate
class _ToggleHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _ToggleHeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 70.h;

  @override
  double get minExtent => 70.h;

  @override
  bool shouldRebuild(covariant _ToggleHeaderDelegate oldDelegate) {
    return false;
  }
}