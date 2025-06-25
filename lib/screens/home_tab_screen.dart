import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/price_tag.dart';
import 'package:romrom_fe/enums/transaction_type.dart';
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
  final PageController _pageController = PageController();
  List<HomeFeedItem> _feedItems = [];
  bool _isLoading = true; // 초기 로딩 상태
  bool _isLoadingMore = false; // 추가 아이템 로딩 상태
  bool _hasMoreItems = true; // 더 로드할 아이템이 있는지 여부
  bool _showBlur = false;

  @override
  void initState() {
    super.initState();
    _loadInitialItems();
    _checkFirstMainScreen();
  }

  Future<void> _checkFirstMainScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool('isFirstMainScreen') ?? false;
    setState(() {
      _showBlur = isFirst;
    });
  }

  Future<void> _clearFirstMainScreenFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstMainScreen', false);
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
          List<TransactionType>.from(TransactionType.values)..shuffle();
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

    // 페이지 뷰로 피드 아이템 표시
    return Stack(
      children: [
        Positioned.fill(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              // 리스트의 끝에 가까워지면 더 많은 아이템 로드
              if (scrollInfo is ScrollEndNotification) {
                final currentPage = _pageController.page?.round() ?? 0;
                if (currentPage >= _feedItems.length - 2 &&
                    !_isLoadingMore &&
                    _hasMoreItems) {
                  _loadMoreItems();
                }
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
                  showBlur: _showBlur,
                );
              },
            ),
          ),
        ),
        // 하단 고정 카드 덱 (터치 영역 분리)
        if (!_showBlur)
          Positioned(
            left: 0,
            right: 0,
            bottom: -100.h,
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
        if (!_showBlur)
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

  @override
  void dispose() {
    _pageController.dispose();
    _clearFirstMainScreenFlag();
    super.dispose();
  }
}
