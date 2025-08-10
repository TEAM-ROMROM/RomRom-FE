import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/request_management_item_card.dart';
import 'package:romrom_fe/widgets/common/scrollable_header.dart';
import 'package:romrom_fe/widgets/common/toggle_header_delegate.dart';
import 'package:romrom_fe/widgets/common/toggle_selector.dart';
import 'package:romrom_fe/icons/app_icons.dart';
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
  bool _isScrolled = false;
  Timer? _scrollTimer;

  // 현재 선택된 카드 인덱스
  int _currentCardIndex = 0;
  
  // 카드 컨트롤러
  late PageController _cardController;

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
              viewportFraction: 0.65, // 화면에 보이는 카드의 비율
    );
    
    // 샘플 데이터 추가
    _loadSampleData();
  }
  
  /// 샘플 데이터 로드
  void _loadSampleData() {
    _itemCards.addAll([
      RequestManagementItemCard(
        imageUrl: '',  // 실제 이미지 URL 필요
        category: '스포츠/레저',
        title: '윌슨 블레이드 V9',
        price: 150000,
        likeCount: 10,
        isAiAnalyzed: true,
      ),
      RequestManagementItemCard(
        imageUrl: '',  // 실제 이미지 URL 필요
        category: '스포츠/레저',
        title: '윌슨 블레이드 V8',
        price: 120000,
        likeCount: 5,
        isAiAnalyzed: false,
      ),
      RequestManagementItemCard(
        imageUrl: '',  // 실제 이미지 URL 필요
        category: '디지털/가전',
        title: '아이폰 14 프로 블랙',
        price: 980000,
        likeCount: 23,
        isAiAnalyzed: true,
      ),
      RequestManagementItemCard(
        imageUrl: '',  // 실제 이미지 URL 필요
        category: '패션/의류',
        title: '나이키 에어포스 1 로우',
        price: 89000,
        likeCount: 8,
        isAiAnalyzed: false,
      ),
      RequestManagementItemCard(
        imageUrl: '',  // 실제 이미지 URL 필요
        category: '도서/티켓/음반',
        title: '해리포터 시리즈 전권',
        price: 75000,
        likeCount: 15,
        isAiAnalyzed: false,
      ),
      RequestManagementItemCard(
        imageUrl: '',  // 실제 이미지 URL 필요
        category: '가구/인테리어',
        title: '이케아 책상 세트',
        price: 220000,
        likeCount: 7,
        isAiAnalyzed: true,
      ),
    ]);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _cardController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }

  void _scrollListener() {
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

  /// 토글 상태 변경 (받은 요청/보낸 요청)
  void _onToggleChanged(bool isRight) {
    setState(() {
      _isRightSelected = isRight;
      _currentCardIndex = 0;
    });
    
    _cardController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    // TODO: 필터링된 데이터 로드 로직 추가
  }
  
  /// 카드 페이지 변경 이벤트 처리
  void _onCardPageChanged(int index) {
    setState(() {
      _currentCardIndex = index;
    });
    
    // TODO: 선택된 카드에 따른 요청 목록 필터링
  }
  
  /// 거래 완료된 요청 표시 토글
  void _toggleCompletedRequests(bool value) {
    setState(() {
      _showCompletedRequests = value;
    });
    
    // TODO: 거래 완료된 요청 필터링
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: null,
      body: SafeArea(
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // 스크롤 가능한 헤더
            ScrollableHeader(
              title: '요청 관리',
              isScrolled: innerBoxIsScrolled || _isScrolled,
            ),
            // 토글 위젯을 고정 헤더로 추가
            SliverPersistentHeader(
              pinned: true,
              delegate: ToggleHeaderDelegate(
                child: ToggleSelector(
                  leftText: '받은 요청',
                  rightText: '보낸 요청',
                  isRightSelected: _isRightSelected,
                  onToggleChanged: _onToggleChanged,
                ),
              ),
            ),
          ],
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              // 1. 물품 카드 캐러셀 섹션
              _buildItemCardsCarousel(),
              
              // 2. 페이지 인디케이터
              _buildPageIndicator(),
              
              // 3. 요청 목록 헤더 섹션 (제목 + 필터 토글)
              _buildRequestListHeader(),
              
              // 4. 요청 목록 리스트
              _buildFullRequestItemsList(),
            ],
          ),
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
      height: 358.h,
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
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '요청 목록',
            style: CustomTextStyles.h3,
          ),
          Row(
            children: [
              Text(
                '거래 완료된 글 표시',
                style: CustomTextStyles.p2.copyWith(
                  color: AppColors.opacity60White,
                ),
              ),
              SizedBox(width: 8.w),
              Switch(
                value: _showCompletedRequests,
                onChanged: _toggleCompletedRequests,
                activeColor: AppColors.primaryYellow,
                activeTrackColor: AppColors.primaryYellow.withValues(alpha: 0.5),
                inactiveThumbColor: AppColors.opacity60White,
                inactiveTrackColor: AppColors.opacity20White,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 요청 아이템 리스트 구현 (ListView 내부에서 사용)
  Widget _buildFullRequestItemsList() {
    // TODO: 실제 데이터로 구현
    return Column(
      children: List.generate(
        4, // 테스트용 항목 수
        (index) {
          // 샘플 데이터로 다양한 상태 표시
          final hasNewBadge = index == 0 || index == 1;
          final status = index == 3 ? RequestStatus.chatting : 
                         index == 2 ? RequestStatus.completed :
                         RequestStatus.pending;
                         
          return Column(
            children: [
              _buildRequestItem(
                title: '제목 위치·시간',
                hasNewBadge: hasNewBadge,
                status: status,
              ),
              if (index < 3) // 마지막 아이템 다음에는 구분선 없음
                Divider(
                  color: AppColors.opacity10White,
                  height: 1.h,
                ),
            ],
          );
        },
      ),
    );
  }
  
  // 사용되지 않는 메서드 제거

  /// 개별 요청 아이템 위젯 구현
  Widget _buildRequestItem({
    required String title,
    bool hasNewBadge = false,
    RequestStatus status = RequestStatus.pending,
  }) {
    return Container(
      height: 156.h,
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 영역: 제목, 뱃지, 옵션 버튼
          Row(
            children: [
              // 프로필 이미지
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: AppColors.opacity20White,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(width: 12.w),
              // 제목 영역
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title,
                      style: CustomTextStyles.p1.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (hasNewBadge) ...[                      
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          'N',
                          style: CustomTextStyles.p2.copyWith(
                            color: AppColors.textColorWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // 옵션 버튼
              IconButton(
                icon: Icon(
                  AppIcons.dotsVertical,
                  size: 20.sp,
                  color: AppColors.textColorWhite,
                ),
                onPressed: () {
                  // TODO: 옵션 메뉴 표시
                },
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // 하단 영역: 액션 버튼들
          Row(
            children: [
              _buildActionButton('추가금', onPressed: () {}),
              SizedBox(width: 8.w),
              _buildActionButton('직거래', onPressed: () {}),
              SizedBox(width: 8.w),
              _buildActionButton('택배', onPressed: () {}),
              const Spacer(),
              // 상태별 버튼
              _buildStatusButton(status),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 액션 버튼 위젯
  Widget _buildActionButton(String label, {required VoidCallback onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondaryBlack,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: CustomTextStyles.p2,
      ),
    );
  }
  
  /// 상태 버튼 위젯
  Widget _buildStatusButton(RequestStatus status) {
    switch (status) {
      case RequestStatus.chatting:
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryYellow,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
          onPressed: () {},
          child: Text(
            '채팅 중',
            style: CustomTextStyles.p2.copyWith(
              color: AppColors.textColorBlack,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case RequestStatus.completed:
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.opacity20White,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
          onPressed: null,
          child: Text(
            '거래 완료',
            style: CustomTextStyles.p2.copyWith(
              color: AppColors.opacity60White,
            ),
          ),
        );
      case RequestStatus.cancelled:
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.opacity20White,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
          onPressed: null,
          child: Text(
            '거래 취소',
            style: CustomTextStyles.p2.copyWith(
              color: AppColors.opacity60White,
            ),
          ),
        );
      case RequestStatus.pending:
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warningRed,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
          onPressed: () {},
          child: Text(
            '거래 완료',
            style: CustomTextStyles.p2.copyWith(
              color: AppColors.textColorWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    }
  }
}





/// 요청 상태 열거형
enum RequestStatus {
  pending,    // 대기 중
  chatting,   // 채팅 중
  completed,  // 완료됨
  cancelled,  // 취소됨
}