import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/trade_request.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/home_feed_item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/services/apis/item_api.dart';

import 'package:romrom_fe/enums/item_condition.dart' as item_cond;
import 'package:romrom_fe/services/apis/trade_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/common_delete_modal.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/flip_card_spin.dart';
import 'package:romrom_fe/widgets/home_tab_card_hand.dart';
import 'package:romrom_fe/widgets/home_feed_item_widget.dart';
import 'package:romrom_fe/widgets/item_card.dart';

import 'package:romrom_fe/services/location_service.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';

/// 홈 탭 화면
class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  // HomeTabScreen의 상태에 접근하기 위한 GlobalKey
  static final GlobalKey<State<HomeTabScreen>> globalKey =
      GlobalKey<State<HomeTabScreen>>();

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
  // ignore: unused_field
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

  // 내 카드 목록 (나중에 API에서 가져올 예정)
  List<Item> _myCards = [];

  // 선택된 거래 옵션 저장 리스트
  final List<ItemTradeOption> _selectedTradeOptions = [];

  @override
  void initState() {
    super.initState();
    _loadInitialItems();
    _loadMyCards();
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

  /// 첫 물건 등록 후 상세 페이지로 이동 (외부 호출용)
  void navigateToItemDetail(String itemId) {
    debugPrint('====================================');
    debugPrint('HomeTabScreen.navigateToItemDetail 호출됨: itemId=$itemId');
    debugPrint('mounted: $mounted');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('PostFrameCallback 실행됨');
      if (mounted) {
        debugPrint('상세 페이지로 네비게이션 시작...');
        // 화면 크기 가져오기
        final screenWidth = MediaQuery.of(context).size.width;
        final imageHeight = screenWidth; // 정사각형 이미지

        // context.navigateTo() 헬퍼 사용 (iOS 스와이프 백 지원)
        context.navigateTo(
          screen: ItemDetailDescriptionScreen(
            itemId: itemId,
            imageSize: Size(screenWidth, imageHeight),
            currentImageIndex: 0,
            heroTag: 'first_item_$itemId',
            isMyItem: true,
            isRequestManagement: false,
          ),
        );

        // 상세 화면에서 돌아왔을 때 코치마크 표시
        debugPrint('상세 화면에서 돌아옴! 이제 코치마크를 표시합니다.');
        _checkAndShowCoachMark();

        debugPrint('상세 페이지 네비게이션 완료');
      } else {
        debugPrint('⚠️ HomeTabScreen이 mounted되지 않음!');
      }
    });
    debugPrint('====================================');
  }

  /// 홈 화면 블러 표시 로직
  ///
  /// 블러 표시 조건:
  /// - 내 물건이 0개일 때 (실제 물건 개수 기준)
  ///
  /// 코치마크 표시 조건:
  /// - 첫 물품 등록 후 상세 화면에서 돌아올 때만 표시
  /// - _checkAndShowCoachMark()에서 처리
  Future<void> _checkFirstMainScreen() async {
    debugPrint('====================================');
    debugPrint('_checkFirstMainScreen 호출됨');
    try {

      // 블러 표시 여부: 내 물건 개수가 0개일 때
      final bool shouldShowBlur = _myCards.isEmpty;

      debugPrint('조건 체크:');
      debugPrint('  - 내 물건 개수: ${_myCards.length}');
      debugPrint('  - shouldShowBlur: $shouldShowBlur');

      setState(() {
        _isBlurShown = shouldShowBlur;
      });

      // 코치마크는 여기서 표시하지 않음!
      // 첫 물품 등록 후 상세 화면 복귀 시에만 _checkAndShowCoachMark()에서 표시
      debugPrint('코치마크는 첫 물품 등록 플로우에서만 표시됨');
    } catch (e) {
      debugPrint('⚠️ 첫 화면 체크 실패: $e');
      setState(() {
        _isBlurShown = false;
      });
    }
    debugPrint('====================================');
  }

  /// 코치마크를 표시해야 하는지 체크하고 표시 (상세 화면에서 돌아올 때 호출)
  Future<void> _checkAndShowCoachMark() async {
    debugPrint('====================================');
    debugPrint('_checkAndShowCoachMark 호출됨 (상세 화면에서 돌아옴)');
    try {
      final userInfo = UserInfo();
      await userInfo.getUserInfo();

      debugPrint('UserInfo 로드 완료:');
      debugPrint('  - isFirstItemPosted: ${userInfo.isFirstItemPosted}');
      debugPrint('  - isCoachMarkShown: ${userInfo.isCoachMarkShown}');

      // 코치마크 표시 여부: 첫 물건 등록 완료 && 코치마크 미표시
      final bool shouldShowCoachMark = (userInfo.isFirstItemPosted == true) &&
          (userInfo.isCoachMarkShown != true);

      debugPrint('조건 체크:');
      debugPrint('  - shouldShowCoachMark: $shouldShowCoachMark');

      // 코치마크 표시
      if (shouldShowCoachMark) {
        debugPrint('✅ 코치마크 표시 조건 충족!');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            debugPrint('코치마크 오버레이 표시 시작...');
            _showCoachMarkOverlay();
          }
        });
      } else {
        debugPrint('❌ 코치마크 표시 조건 불충족');
      }
    } catch (e) {
      debugPrint('⚠️ 코치마크 체크 실패: $e');
    }
    debugPrint('====================================');
  }

  // 코치마크 닫기
  void _closeCoachMark() async {
    _removeCoachMarkOverlay();

    // 코치마크 표시 완료 플래그 설정
    final userInfo = UserInfo();
    await userInfo.getUserInfo();
    await userInfo.saveLoginStatus(
      isFirstLogin: userInfo.isFirstLogin ?? false,
      isFirstItemPosted: userInfo.isFirstItemPosted ?? false,
      isItemCategorySaved: userInfo.isItemCategorySaved ?? false,
      isMemberLocationSaved: userInfo.isMemberLocationSaved ?? false,
      isMarketingInfoAgreed: userInfo.isMarketingInfoAgreed ?? false,
      isRequiredTermsAgreed: userInfo.isRequiredTermsAgreed ?? false,
      isCoachMarkShown: true,
    );

    debugPrint('코치마크 닫기: isCoachMarkShown = true');
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

      final feedItems =
          await _convertToFeedItems(response.itemPage?.content ?? []);

      setState(() {
        _feedItems
          ..clear()
          ..addAll(feedItems);
        _hasMoreItems = !(response.itemPage?.content.isEmpty ?? true);
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

      final newItems =
          await _convertToFeedItems(response.itemPage?.content ?? []);

      setState(() {
        _feedItems.addAll(newItems);
        _hasMoreItems = !(response.itemPage?.content.isEmpty ?? true);
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
  Future<List<HomeFeedItem>> _convertToFeedItems(List<Item> details) async {
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
          locationText =
              '${address.siDo} ${address.siGunGu} ${address.eupMyoenDong}';
        }
      }

      final feedItem = HomeFeedItem(
        id: index + _feedItems.length + 1,
        itemUuid: d.itemId,
        name: d.itemName ?? ' ',
        price: d.price ?? 0,
        location: locationText,
        date: d.createdDate is DateTime
            ? d.createdDate as DateTime
            : DateTime.now(),
        itemCondition: cond,
        transactionTypes: opts,
        profileUrl:
            d.member?.profileUrl ?? '', // FIXME: 프로필 URL이 없을 경우 에셋 사진으로 대체
        likeCount: d.likeCount ?? 0,
        imageUrls: d.imageUrlList, // List<String>
        description: d.itemDescription ?? '',
        hasAiAnalysis: false,
        latitude: d.latitude,
        longitude: d.longitude,
        authorMemberId: d.member?.memberId, // 게시글 작성자 ID
      );

      feedItems.add(feedItem);
    }

    return feedItems;
  }

  /// 내 카드(물품) 목록 로드
  Future<void> _loadMyCards() async {
    try {
      final itemApi = ItemApi();
      final response = await itemApi.getMyItems(
        ItemRequest(
            pageNumber: 0,
            pageSize: 10,
            itemStatus: ItemStatus.available.serverName),
      );

      if (!mounted) return;

      final myItems = response.itemPage?.content ?? [];
      setState(() {
        _myCards = myItems;
        // 내 물건 개수에 따라 블러 상태 업데이트
        _isBlurShown = myItems.isEmpty;
      });

      debugPrint('내 카드 로딩 완료: ${myItems.length}개, 블러 표시: ${myItems.isEmpty}');
    } catch (e) {
      debugPrint('내 카드 로딩 실패: $e');
      // 테스트용 더미 데이터
      setState(() {
        // FIXME : 테스트용더미데이텅
      });
    }
  }

  /// 카드 드롭 핸들러 (거래 요청)
  void _handleCardDrop(String cardId) async {
    final cardData = _myCards.firstWhere((card) => card.itemId == cardId);

    // 다이얼로그 띄우기 전에 (선택) 이미지 프리캐시
    await precacheImage(
        NetworkImage(
          cardData.primaryImageUrl != null
              ? cardData.primaryImageUrl!
              : 'https://picsum.photos/400/300',
        ),
        context);

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return Material(
          type: MaterialType.transparency,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Center(
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 40.0.w, vertical: 65.0.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 5.h),
                    SizedBox(
                      width: 310.w,
                      height: 496.h,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          FlipCardSpin(
                            front: SizedBox(
                              height: 496.h,
                              child: ItemCard(
                                // 실제 카드 데이터 전달
                                itemId: cardData.itemId!,
                                itemName: cardData.itemName!,
                                itemCategoryLabel:
                                    ItemCategories.fromServerName(
                                            cardData.itemCategory!)
                                        .label,
                                itemCardImageUrl:
                                    cardData.primaryImageUrl != null
                                        ? cardData.primaryImageUrl!
                                        : 'https://picsum.photos/400/300',
                                onOptionSelected: (selectedOption) {
                                  debugPrint('선택된 거래 옵션: $selectedOption');
                                  // 선택된 거래 옵션을 리스트에 추가
                                  setState(() {
                                    if (!_selectedTradeOptions
                                        .contains(selectedOption)) {
                                      _selectedTradeOptions.add(selectedOption);
                                    }
                                  });
                                },
                              ),
                            ),
                            back: SizedBox(
                              width: 310.w,
                              height: 496.h,
                              child: ItemCard(
                                // 실제 카드 데이터 전달
                                itemId: cardData.itemId!,
                                itemName: cardData.itemName!,
                                itemCategoryLabel:
                                    ItemCategories.fromServerName(
                                            cardData.itemCategory!)
                                        .label,
                                itemCardImageUrl:
                                    cardData.primaryImageUrl != null
                                        ? cardData.primaryImageUrl!
                                        : 'https://picsum.photos/400/300',
                                onOptionSelected: (selectedOption) {
                                  debugPrint('선택된 거래 옵션: $selectedOption');
                                  // 선택된 거래 옵션을 리스트에 추가
                                  setState(() {
                                    if (!_selectedTradeOptions
                                        .contains(selectedOption)) {
                                      _selectedTradeOptions.add(selectedOption);
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CompletionButton(
                          isEnabled: true,
                          buttonText: '취소',
                          buttonWidth: 130,
                          buttonHeight: 44,
                          enabledBackgroundColor:
                              AppColors.transactionRequestDialogCancelButton,
                          enabledOnPressed: () {
                            // 선택된 옵션 초기화
                            setState(() {
                              _selectedTradeOptions.clear();
                            });
                            Navigator.pop(context);
                          },
                        ),
                        CompletionButton(
                          isEnabled: true,
                          buttonText: '요청 보내기',
                          buttonWidth: 171,
                          buttonHeight: 44,
                          enabledOnPressed: () async {
                            try {
                              final api = TradeApi();

                              // 거래 요청 API 호출
                              await api.requestTrade(TradeRequest(
                                giveItemId: cardData.itemId!,
                                takeItemId:
                                    _feedItems[_currentFeedIndex].itemUuid,
                                itemTradeOptions: _selectedTradeOptions
                                    .map((option) => option.serverName)
                                    .toList(),
                              ));
                            } catch (e) {
                              debugPrint('거래 요청 중 오류: $e');
                              // 에러 코드 파싱
                              final messageForUser =
                                  ErrorUtils.getErrorMessage(e);

                              await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => CommonDeleteModal(
                                  description: messageForUser,
                                  leftText: '확인',
                                  onRight: () {
                                    Navigator.of(context).pop(); // 모달 닫기
                                  },
                                  onLeft: () => Navigator.of(context).pop(),
                                ),
                              );
                            } finally {
                              // 선택된 옵션 초기화
                              setState(() {
                                _selectedTradeOptions.clear();
                              });

                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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
            bottom: -120.h, // 네비게이션 바 위에 표시
            child: HomeTabCardHand(
              cards: _myCards,
              onCardDrop: _handleCardDrop,
            ),
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
      ],
    );
  }
}
