import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';

import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/request_management_item_card.dart';
import 'package:romrom_fe/widgets/common/completed_toggle_switch.dart';
import 'package:romrom_fe/widgets/common/glass_header_delegate.dart';
import 'package:romrom_fe/widgets/common/trade_status_tag.dart';
import 'package:romrom_fe/widgets/request_list_item_card_widget.dart';
import 'package:romrom_fe/widgets/sent_request_item_card.dart';
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

  Future<void> _loadSampleData({bool isRefresh = false}) async {
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
                onRefresh: () => _loadSampleData(isRefresh: true),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: GlassHeaderDelegate(
                        headerTitle: '요청 관리',
                        toggle: GlassHeaderToggleBuilder.buildDefaultToggle(
                          animation: _toggleAnimation,
                          isRightSelected: _isRightSelected,
                          onLeftTap: () => _onToggleChanged(false),
                          onRightTap: () => _onToggleChanged(true),
                          leftText: '받은 요청',
                          rightText: '보낸 요청',
                        ),
                        statusBarHeight:
                            MediaQuery.of(context).padding.top, // ★ 꼭 전달
                        toolbarHeight: 58.h,
                        toggleHeight: 70.h,
                        expandedExtra: 32.h, // 큰 제목/여백
                        enableBlur: _isScrolled, // 스크롤 시 더 진해지게
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. 물품 카드 캐러셀 섹션 (받은 요청일 때만 표시)
                          if (!_isRightSelected) ...[
                            SizedBox(height: 10.h),
                            _buildItemCardsCarousel(),
                          ],

                          // 2. 페이지 인디케이터 (받은 요청일 때만 표시)
                          if (!_isRightSelected) _buildPageIndicator(),

                          // 3. 요청 목록 헤더 섹션 (제목 + 필터 토글)
                          _buildRequestListHeader(),

                          // 4. 요청 목록 리스트
                          _buildFullRequestItemsList(),

                          SizedBox(height: 100.h), // 하단 여백
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
    // 보낸 요청에서는 헤더 표시 안함
    if (_isRightSelected) {
      return const SizedBox.shrink();
    }

    // 받은 요청에서만 헤더 표시
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목과 토글을 한 줄에 배치
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 제목
              Text(
                '요청 목록',
                style: TextStyle(
                  color: AppColors.textColorWhite,
                  fontFamily: 'Pretendard',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
              // 완료된 요청 필터 토글
              Row(
                children: [
                  Text(
                    '거래완료된 글표시',
                    style: CustomTextStyles.p3.copyWith(
                      color: const Color(0x80FFFFFF),
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.5.sp,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  CompletedToggleSwitch(
                    value: _showCompletedRequests,
                    onChanged: _toggleCompletedRequests,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // 설명 텍스트
          Text(
            '내 물건에 온 교환 요청이에요',
            style: TextStyle(
              color: const Color(0xFFFFFFCC),
              fontFamily: 'Pretendard',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  /// 요청 목록 리스트
  Widget _buildFullRequestItemsList() {
    // 보낸 요청인 경우
    if (_isRightSelected) {
      return _buildSentRequestsList();
    }

    // 받은 요청인 경우 (기존 코드)
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
        'tradeOptions': [
          ItemTradeOption.directOnly,
          ItemTradeOption.extraCharge
        ],
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

  /// 보낸 요청 목록
  Widget _buildSentRequestsList() {
    // 테스트용 샘플 데이터
    final List<Map<String, dynamic>> sentRequests = [
      {
        'myItemImageUrl': 'https://picsum.photos/200/200?random=10',
        'otherItemImageUrl': 'https://picsum.photos/200/200?random=11',
        'otherUserProfileUrl': 'https://picsum.photos/50/50?random=12',
        'title': '나이키 에어맥스 교환 요청',
        'location': '광진구 화양동',
        'createdDate': DateTime.now().subtract(const Duration(hours: 2)),
        'tradeOptions': [
          ItemTradeOption.extraCharge,
          ItemTradeOption.directOnly,
          ItemTradeOption.deliveryOnly
        ],
        'tradeStatus': TradeStatus.chatting,
      },
      {
        'myItemImageUrl': 'https://picsum.photos/200/200?random=13',
        'otherItemImageUrl': 'https://picsum.photos/200/200?random=14',
        'otherUserProfileUrl': 'https://picsum.photos/50/50?random=15',
        'title': '애플워치 교환하실 분',
        'location': '서초구 방배동',
        'createdDate': DateTime.now().subtract(const Duration(days: 1)),
        'tradeOptions': [ItemTradeOption.directOnly],
        'tradeStatus': TradeStatus.completed,
      },
      {
        'myItemImageUrl': 'https://picsum.photos/200/200?random=16',
        'otherItemImageUrl': 'https://picsum.photos/200/200?random=17',
        'otherUserProfileUrl': 'https://picsum.photos/50/50?random=18',
        'title': '노스페이스 패딩 교환',
        'location': '송파구 잠실동',
        'createdDate': DateTime.now().subtract(const Duration(hours: 5)),
        'tradeOptions': [
          ItemTradeOption.deliveryOnly,
          ItemTradeOption.extraCharge
        ],
        'tradeStatus': null,
      },
    ];

    // 보낸 요청은 필터링 없이 모든 요청 표시
    if (sentRequests.isEmpty) {
      return Container(
        height: 200.h,
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Center(
          child: Text(
            '보낸 요청이 없습니다',
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
        children: [
          SizedBox(height: 24.h), // 토글에서 첫 아이템까지 간격
          ...sentRequests.map((request) {
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: SentRequestItemCard(
                myItemImageUrl: request['myItemImageUrl'],
                otherItemImageUrl: request['otherItemImageUrl'],
                otherUserProfileUrl: request['otherUserProfileUrl'],
                title: request['title'],
                location: request['location'],
                createdDate: request['createdDate'],
                tradeOptions: request['tradeOptions'],
                tradeStatus: request['tradeStatus'],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// (사용 안 함) 로컬 헤더 delegate 제거됨. 공통 GlassHeaderDelegate를 사용합니다.
