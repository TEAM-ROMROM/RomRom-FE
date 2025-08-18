import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/home_feed_item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/responses/item_detail.dart';
import 'package:romrom_fe/services/apis/item_api.dart';

import 'package:romrom_fe/enums/item_condition.dart' as item_cond;
import 'package:romrom_fe/widgets/fan_card_dial.dart';
import 'package:romrom_fe/widgets/home_feed_item_widget.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:romrom_fe/screens/report_screen.dart';
import 'package:romrom_fe/widgets/common/report_menu_button.dart';
import 'package:romrom_fe/widgets/common/common_success_modal.dart';
import 'package:romrom_fe/services/location_service.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

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
  final List<HomeFeedItem> _feedItems = [];
  int _currentPage = 0; // 페이징 용(데이터)
  int _currentFeedIndex = 0; // 화면 상 현재 보고 있는 피드 인덱스
  final int _pageSize = 10;
  // 초기 로딩 상태
  bool _isLoading = true;
  // 추가 아이템 로딩 상태
  bool _isLoadingMore = false;
  // 더 로드할 아이템 여부
  bool _hasMoreItems = true;
  // 블러 효과 표시 여부
  bool _isBlurShown = false;
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

  /// 메인화면 첫 진입 여부와 "내 물품 보유 여부"를 함께 고려해
  /// 블러·코치마크 노출 여부를 결정한다.
  ///
  /// 조건
  /// 1) 사용자가 **등록한 물품이 하나도 없고**
  /// 2) 앱 최초 진입일 때(isFirstMainScreen == true)
  /// → 블러 & 코치마크 ON
  ///
  /// 그 외에는 블러·코치마크 OFF
  Future<void> _checkFirstMainScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isFirst = prefs.getBool('isFirstMainScreen') ?? true;

    bool userHasItem = false;
    try {
      // 내 물품이 하나라도 있는지 확인 (pageSize=1로 최소 데이터 호출)
      final itemApi = ItemApi();
      final response = await itemApi.getMyItems(
        ItemRequest(pageNumber: 0, pageSize: 1),
      );

      userHasItem = (response.itemDetailPage?.content?.isNotEmpty ?? false);
    } catch (e) {
      debugPrint('블러 상태 결정용 내 물품 조회 실패: $e');
      // 실패 시에는 "없다"고 간주해 기존 로직 유지
    }

    final bool shouldShowBlur = !userHasItem && isFirst;

    setState(() {
      _isBlurShown = shouldShowBlur;
    });

    // 블러를 보여줄 필요가 없다면 최초 진입 플래그도 바로 해제 (다음 진입 시 재호출 방지)
    if (!shouldShowBlur) {
      await prefs.setBool('isFirstMainScreen', false);
    }

    // 코치마크가 필요한 경우 오버레이 표시
    if (shouldShowBlur) {
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
      final itemApi = ItemApi();
      final response = await itemApi.getItems(ItemRequest(
        pageNumber: _currentPage,
        pageSize: _pageSize,
      ));

      if (!mounted) return;

      final feedItems = await _convertToFeedItems(response.itemDetailPage?.content ?? []);
      
      setState(() {
        _feedItems
          ..clear()
          ..addAll(feedItems);
        _hasMoreItems = !(response.itemDetailPage?.last ?? true);
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
      _currentPage += 1;
      final itemApi = ItemApi();
      final response = await itemApi.getItems(ItemRequest(
        pageNumber: _currentPage,
        pageSize: _pageSize,
      ));

      final newItems = await _convertToFeedItems(response.itemDetailPage?.content ?? []);

      setState(() {
        _feedItems.addAll(newItems);
        _hasMoreItems = !(response.itemDetailPage?.last ?? true);
        _isLoadingMore = false;
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

  /// ItemDetail 리스트를 HomeFeedItem 리스트로 변환
  Future<List<HomeFeedItem>> _convertToFeedItems(List<ItemDetail> details) async {
    final feedItems = <HomeFeedItem>[];
    
    for (int index = 0; index < details.length; index++) {
      final d = details[index];

      // 카테고리/상태/옵션 매핑
      ItemCondition cond = ItemCondition.newItem;
      try {
        cond = item_cond.ItemCondition.values
            .firstWhere((e) => e.serverName == d.itemCondition);
      } catch (_) {}

      final opts = <ItemTradeOption>[];
      if (d.itemTradeOptions != null) {
        for (final s in d.itemTradeOptions!) {
          try {
            opts.add(
                ItemTradeOption.values.firstWhere((e) => e.serverName == s));
          } catch (_) {}
        }
      }

      // 위치 정보 변환
      String locationText = '미지정';
      if (d.latitude != null && d.longitude != null) {
        final address = await LocationService().getAddressFromCoordinates(
          NLatLng(d.latitude!, d.longitude!),
        );
        if (address != null) {
          locationText = '${address.siDo} ${address.siGunGu} ${address.eupMyoenDong}';
        }
      }

      final feedItem = HomeFeedItem(
        id: index + _feedItems.length + 1,
        itemUuid: d.itemId,
        price: d.price ?? 0,
        location: locationText,
        date: d.createdDate ?? '',
        itemCondition: cond,
        transactionTypes: opts,
        priceTag: null,
        profileImageUrl:
            'https://picsum.photos/100/100?random=${index + 1}', //FIXME: 프로필 이미지 추가 필요
        likeCount: d.likeCount ?? 0,
        imageUrls: d.itemImageUrls ?? [''],
        description: d.itemDescription ?? '',
        hasAiAnalysis: false,
        aiPrice: false, // TODO: API에서 aiPrice 정보 받아와야 함
        latitude: d.latitude,
        longitude: d.longitude,
        isLiked: false, // TODO: API에서 좋아요 상태 받아와야 함
      );
      
      feedItems.add(feedItem);
    }
    
    return feedItems;
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
              // 블러가 활성화된 경우 스와이프(스크롤) 동작을 비활성화해 첫 화면 고정
              physics: _isBlurShown
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: _feedItems.length + (_hasMoreItems ? 1 : 0),
              onPageChanged: (index) {
                // 블러가 켜져 있으면 페이지 변경 자체가 발생하지 않으므로, 여기서는 블러 OFF 상태만 처리
                if (!_isBlurShown && index < _feedItems.length) {
                  setState(() {
                    _currentFeedIndex = index;
                  });
                }
              },
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
            child: ReportMenuButton(
              onReportPressed: () async {
                final bool? reported = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportScreen(
                      itemId: _feedItems[_currentFeedIndex].itemUuid ?? '',
                    ),
                  ),
                );

                if (reported == true && mounted) {
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => CommonSuccessModal(
                      message: '신고가 접수되었습니다.',
                      onConfirm: () => Navigator.of(context).pop(),
                    ),
                  );
                }
              },
            ),
          ),
      ],
    );
  }
}
