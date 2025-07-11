import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/enums/price_tag.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/home_feed_item.dart';
import 'package:romrom_fe/widgets/fan_card_dial.dart';
import 'package:romrom_fe/widgets/home_feed_item_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 홈 탭 화면
class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  // 메인 콘텐츠 페이지 컨트롤러
  final PageController _pageController = PageController();
  // 코치마크 전용 페이지 컨트롤러
  final PageController _coachMarkPageController = PageController();
  // 피드 아이템 목록
  List<HomeFeedItem> _feedItems = [];
  // 초기 로딩 상태
  bool _isLoading = true;
  // 추가 아이템 로딩 상태
  bool _isLoadingMore = false;
  // 더 로드할 아이템 여부
  bool _hasMoreItems = true;
  // 블러 효과 표시 여부
  bool _isBlurShown = false;
  // 코치마크 표시 여부
  bool _isCoachMarkShown = false;
  // 코치마크 현재 페이지 상태 관리 (성능 최적화)
  final ValueNotifier<int> _coachMarkPageNotifier = ValueNotifier<int>(0);
  // 오버레이 엔트리
  OverlayEntry? _overlayEntry;

  // 코치마크 이미지 목록
  final List<String> _coachMarkImages = [
    'assets/images/coachMark1.png',
    'assets/images/coachMark2.png',
    'assets/images/coachMark3.png',
    'assets/images/coachMark4.png',
    'assets/images/coachMark5.png',
    'assets/images/coachMark6.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialItems();
    _checkFirstMainScreen();
  }

  @override
  void dispose() {
    _removeCoachMarkOverlay();
    _pageController.dispose();
    _coachMarkPageController.dispose();
    _coachMarkPageNotifier.dispose();
    super.dispose();
  }

  /// 메인화면 첫 진입 여부 확인 및 코치마크 표시 트리거
  Future<void> _checkFirstMainScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool('isFirstMainScreen') ?? true;

    setState(() {
      _isBlurShown = isFirst; // 첫 진입 시 블러 효과 표시
      _isCoachMarkShown = isFirst; // 첫 진입 시 코치마크 표시
    });

    // 코치마크가 필요한 경우 오버레이 표시
    if (_isCoachMarkShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCoachMarkOverlay();
      });
    }
  }

  /// 코치마크 노출 플래그 해제 (이후 재진입 시 코치마크 미노출)
  Future<void> _clearFirstMainScreenFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstMainScreen', false);
  }

  // 코치마크 닫기
  void _closeCoachMark() {
    _removeCoachMarkOverlay();
    _clearFirstMainScreenFlag();
  }

  // 코치마크 오버레이 표시 (성능/메모리/오류 처리 최적화)
  void _showCoachMarkOverlay() {
    _removeCoachMarkOverlay(); // 기존 오버레이 정리
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildCoachMarkOverlay(),
    );
    if (mounted && _overlayEntry != null) {
      try {
        Overlay.of(context).insert(_overlayEntry!);
        debugPrint('코치마크: 오버레이 생성 완료');
      } on FlutterError catch (e) {
        debugPrint('오버레이 삽입 오류: $e');
        _overlayEntry = null;
      } catch (e) {
        debugPrint('오버레이 삽입 알 수 없는 오류: $e');
        _overlayEntry = null;
      }
    }
  }

  Widget _buildCoachMarkOverlay() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.opacity70Black,
        child: Column(
          children: [
            Expanded(child: _buildCoachMarkPageView()),
            _buildPageIndicators(),
            _buildCoachMarkCloseButton(),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachMarkPageView() {
    return PageView.builder(
      controller: _coachMarkPageController,
      itemCount: _coachMarkImages.length,
      onPageChanged: (page) {
        debugPrint('코치마크 페이징: 페이지 변경 $page');
        _coachMarkPageNotifier.value = page;
      },
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            if (index < _coachMarkImages.length - 1) {
              debugPrint('코치마크 이벤트: 이미지 탭 - 다음 페이지 ${index + 1}');
              _coachMarkPageController.animateToPage(
                index + 1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              debugPrint('코치마크 이벤트: 마지막 이미지 탭 - 코치마크 닫기');
              _closeCoachMark();
            }
          },
          child: Image.asset(
            _coachMarkImages[index],
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('오류: 이미지 로드 실패 - ${_coachMarkImages[index]} - $error');
              return Center(
                child: Text(
                  '이미지 로드 실패: ${_coachMarkImages[index]}',
                  style: const TextStyle(color: AppColors.textColorWhite),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPageIndicators() {
    return ValueListenableBuilder<int>(
      valueListenable: _coachMarkPageNotifier,
      builder: (context, currentPage, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _coachMarkImages.length,
            (index) {
              final isCurrentPage = index == currentPage;
              return GestureDetector(
                onTap: () {
                  debugPrint('코치마크 이벤트: 인디케이터 탭 - 페이지 $index');
                  _coachMarkPageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isCurrentPage ? 12.w : 8.w,
                  height: isCurrentPage ? 12.w : 8.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrentPage
                        ? AppColors.primaryYellow
                        : AppColors.opacity50White,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCoachMarkCloseButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _closeCoachMark,
          child: const Text(
            '닫기',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }

  // 오버레이 안전 제거 (메모리 누수 방지)
  void _removeCoachMarkOverlay() {
    if (_overlayEntry != null) {
      try {
        _overlayEntry!.remove();
        debugPrint('코치마크: 오버레이 제거 완료');
      } catch (e) {
        debugPrint('오류: 오버레이 제거 실패 - $e');
      }
      _overlayEntry = null;
    }
  }

  /// 초기 아이템 로드
  Future<void> _loadInitialItems() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      setState(() {
        _feedItems = _getMockItems();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('피드 로딩 실패: $e')),
      );
    }
  }

  /// 추가 아이템 로드
  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || !_hasMoreItems) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // 실제 앱에서는 페이지네이션을 사용한 API 호출
      await Future.delayed(const Duration(seconds: 1));

      final newItems = _getMockItems(startId: _feedItems.length + 1);

      setState(() {
        _feedItems.addAll(newItems);
        _isLoadingMore = false;

        // 데이터가 일정량 이상이면 더 이상 로드하지 않음 (시뮬레이션)
        if (_feedItems.length > 30) {
          _hasMoreItems = false;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('추가 피드 로딩 실패: $e')),
        );
      }
    }
  }

  /// 테스트용 아이템 생성
  /// FIXME: 실제 앱에서는 API를 통해 데이터를 받아와야 함.
  List<HomeFeedItem> _getMockItems({int startId = 1}) {
    // 테스트용 이미지 URL
    final List<String> placeholderImages = [
      'https://picsum.photos/400/600?random=1',
      'https://picsum.photos/400/600?random=2',
      'https://picsum.photos/400/600?random=3',
      'https://picsum.photos/400/600?random=4',
      'https://picsum.photos/400/600?random=5',
    ];

    List<HomeFeedItem> items = [];

    // 랜덤값 생성을 위한 객체
    final random = Random();

    // 사용상태 enum 목록
    const itemConditions = ItemCondition.values;

    // 가격 태그 enum 목록
    const priceTags = PriceTag.values;

    for (int i = 0; i < 5; i++) {
      int id = startId + i;
      bool isEven = id % 2 == 0;

      // 랜덤으로 거래 유형 선택 (1~3개)
      final transactionTypeCount = random.nextInt(2) + 1; // 1~3개 선택
      final shuffledTransactionTypes =
          List<ItemTradeOption>.from(ItemTradeOption.values)..shuffle();
      final selectedTransactionTypes =
          shuffledTransactionTypes.take(transactionTypeCount).toList();

      items.add(
        HomeFeedItem(
          id: id,
          price: isEven ? 120000 : 55000 + (id * 1000),
          location: isEven ? '광진구 화양동' : '송파구 잠실동',
          date: '2025년 1월 ${id + 1}일',
          itemCondition: itemConditions[random.nextInt(itemConditions.length)],
          transactionTypes: selectedTransactionTypes,
          priceTag: isEven ? priceTags[0] : priceTags[1],
          // 짝수 ID는 AI 분석 적정가 표시
          profileImageUrl: 'https://picsum.photos/100/100?random=$id',
          likeCount: isEven ? 4 : 12 + id,
          imageUrls: [
            placeholderImages[id % placeholderImages.length],
            placeholderImages[(id + 1) % placeholderImages.length],
            placeholderImages[(id + 2) % placeholderImages.length],
          ],
          description: isEven
              ? '테니스 라켓과 공 판매합니다. 상태 좋아요.'
              : '신발 판매합니다. 한번도 신지 않은 새상품이에요.',
          hasAiAnalysis: isEven,
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryYellow),
      );
    }

    // 피드 아이템이 없을 때 메시지 표시
    if (_feedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('물품이 없습니다.', style: CustomTextStyles.h3),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialItems,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: AppColors.primaryYellow,
              ),
              child: const Text('새로고침'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (!_isLoadingMore &&
                  _hasMoreItems &&
                  scrollInfo.metrics.pixels ==
                      scrollInfo.metrics.maxScrollExtent) {
                _loadMoreItems();
              }
              return false;
            },
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              controller: _pageController,
              itemCount: _feedItems.length + (_hasMoreItems ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _feedItems.length) {
                  // 리스트 끝에 로딩 인디케이터 표시
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryYellow),
                  );
                }
                return HomeFeedItemWidget(
                  item: _feedItems[index],
                  showBlur: _isBlurShown,
                );
              },
            ),
          ),
        ),
        // 하단 고정 카드 덱 (터치 영역 분리)
        if (!_isBlurShown)
          Positioned(
            left: 0,
            right: 0,
            bottom: -75.h,
            child: const FanCardDial(),
          )
        else
          Positioned(
            left: 0,
            right: 0,
            bottom: 10.h,
            child: SvgPicture.asset(
              'assets/images/first-item-post-text.svg',
              width: 145.w,
            ),
          ),

        /// 더보기 아이콘 버튼
        if (!_isBlurShown)
          Positioned(
            right: 24.w,
            top: MediaQuery.of(context).padding.top, // SafeArea 기준으로 margin 줌
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    // TODO: 더보기 기능 구현
                    debugPrint('더보기 버튼 클릭 - 기능 구현 예정');
                  },
                  child: Icon(AppIcons.dotsVertical,
                      size: 30.sp, color: AppColors.textColorWhite),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
