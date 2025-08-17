import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/request_management_item_card.dart';
import 'package:romrom_fe/widgets/common/completed_toggle_switch.dart';
import 'package:romrom_fe/widgets/common/trade_status_tag_widget.dart';
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
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              _buildHeader(),
              
              // 받은 요청 / 보낸 요청 토글
              _buildToggleSelector(),
              
              SizedBox(height: 24.h),
              
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
    );
  }

  /// 헤더 구현
  Widget _buildHeader() {
    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '요청 관리',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Pretendard',
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 토글 셀렉터 구현
  Widget _buildToggleSelector() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
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

  /// 물품 카드 캐러셀 구현
  Widget _buildItemCardsCarousel() {
    if (_itemCards.isEmpty) {
      return SizedBox(
        height: 200.h,
        child: Center(
          child: Text(
            '등록된 물품이 없습니다.',
            style: CustomTextStyles.p1.copyWith(
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
        itemCount: _itemCards.length,
        onPageChanged: _onCardPageChanged,
        itemBuilder: (context, index) {
          // 현재 선택된 카드인지 여부 확인
          final isActive = index == _currentCardIndex;
          
          return RequestManagementItemCardWidget(
            card: _itemCards[index],
            isActive: isActive,
          );
        },
      ),
    );
  }

  /// 페이지 인디케이터 구현
  Widget _buildPageIndicator() {
    if (_itemCards.isEmpty) {
      return SizedBox(height: 40.h);
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _itemCards.length,
          (index) => Container(
            width: 8.w,
            height: 8.h,
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == _currentCardIndex
                  ? AppColors.primaryYellow
                  : AppColors.opacity20White,
            ),
          ),
        ),
      ),
    );
  }

  /// 요청 목록 헤더 (제목 + 필터 토글) 구현
  Widget _buildRequestListHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 37.h, 16.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목과 토글
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '요청 목록',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Pretendard',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
              Row(
                children: [
                  Text(
                    '거래완료된 글표시',
                    style: TextStyle(
                      color: const Color(0x80FFFFFF),
                      fontFamily: 'Pretendard',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      height: 1.0,
                      letterSpacing: -0.5.sp,
                    ),
                    textAlign: TextAlign.right,
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
            _isRightSelected 
                ? '내가 보낸 교환 요청이예요'
                : '내 물건에 온 교환 요청이예요',
            style: TextStyle(
              color: const Color(0xCCFFFFFF),
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

  /// 요청 목록 리스트 구현
  Widget _buildFullRequestItemsList() {
    // 테스트용 목데이터
    final List<Map<String, dynamic>> mockData = [
      {
        'imageUrl': 'https://picsum.photos/200/200?random=1',
        'title': '나이키 에어맥스 270',
        'address': '강남구',
        'createdDate': DateTime.now().subtract(const Duration(minutes: 30)),
        'isNew': true,
        'tradeOptions': [ItemTradeOption.extraCharge, ItemTradeOption.directOnly],
        'tradeStatus': TradeStatus.chatting,
      },
      {
        'imageUrl': 'https://picsum.photos/200/200?random=2',
        'title': '애플워치 7세대 44mm',
        'address': '서초구',
        'createdDate': DateTime.now().subtract(const Duration(hours: 2)),
        'isNew': false,
        'tradeOptions': [ItemTradeOption.deliveryOnly],
        'tradeStatus': TradeStatus.completed,
      },
      {
        'imageUrl': 'https://picsum.photos/200/200?random=3',
        'title': '아이패드 프로 11인치 3세대',
        'address': '용산구',
        'createdDate': DateTime.now().subtract(const Duration(days: 1)),
        'isNew': false,
        'tradeOptions': [ItemTradeOption.directOnly],
        'tradeStatus': TradeStatus.chatting,
      },
    ];

    // 완료된 요청 필터링
    final filteredData = _showCompletedRequests
        ? mockData
        : mockData.where((item) => item['tradeStatus'] != TradeStatus.completed).toList();
    
    return Padding(
      padding: EdgeInsets.only(top: 24.h),
      child: Column(
        children: filteredData.isEmpty 
            ? [
                Container(
                  height: 100.h,
                  alignment: Alignment.center,
                  child: Text(
                    '아직 요청이 없습니다.',
                    style: TextStyle(
                      color: AppColors.opacity60White,
                      fontFamily: 'Pretendard',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ]
            : filteredData.map((item) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h, left: 16.w, right: 16.w),
                  child: RequestListItemCardWidget(
                    imageUrl: item['imageUrl'],
                    title: item['title'],
                    address: item['address'],
                    createdDate: item['createdDate'],
                    isNew: item['isNew'],
                    tradeOptions: item['tradeOptions'],
                    tradeStatus: item['tradeStatus'],
                    onMenuTap: () {
                      // TODO: 메뉴 액션 구현
                      debugPrint('Menu tapped for ${item['title']}');
                    },
                  ),
                );
              }).toList(),
      ),
    );
  }
}

// 요청 상태 enum
enum RequestStatus {
  pending,
  chatting,
  completed,
}