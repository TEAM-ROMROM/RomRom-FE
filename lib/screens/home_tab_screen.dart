import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/home_feed_item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/requests/trade_request.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/services/apis/trade_api.dart';

import 'package:romrom_fe/enums/item_condition.dart' as item_cond;
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/report_menu_button.dart';
import 'package:romrom_fe/widgets/home_tab_card_hand.dart';
import 'package:romrom_fe/widgets/home_feed_item_widget.dart';
import 'package:romrom_fe/icons/app_icons.dart';

import 'package:romrom_fe/services/location_service.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/screens/notification_screen.dart';
import 'package:romrom_fe/screens/report_screen.dart';
import 'package:romrom_fe/screens/trade_request_screen.dart';

/// 홈 탭 화면
class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  // HomeTabScreen의 상태에 접근하기 위한 GlobalKey
  static final GlobalKey<State<HomeTabScreen>> globalKey = GlobalKey<State<HomeTabScreen>>();

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
  int _currentPage = 0;
  // ignore: unused_field
  int _currentFeedIndex = 0;
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

  /// AI 추천으로 하이라이트할 카드 itemId 목록 (상위 3개)
  List<String> _aiHighlightedItemIds = [];

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

  /// AI 추천 결과를 받아 카드 하이라이트 상태 업데이트
  void _onAiRecommend(List<String> itemIds) {
    setState(() {
      _aiHighlightedItemIds = itemIds;
    });
    debugPrint('AI 추천 하이라이트 업데이트: $itemIds');
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
        final imageHeight = screenWidth;

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
      final bool shouldShowCoachMark = (userInfo.isFirstItemPosted == true) && (userInfo.isCoachMarkShown != true);

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
    _removeCoachMarkOverlay();
    _overlayEntry = OverlayEntry(builder: (context) => _buildCoachMarkOverlay());
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
          children: List.generate(_coachMarkImages.length, (index) {
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
                  color: isCurrentPage ? AppColors.primaryYellow : AppColors.opacity50White,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildCoachMarkCloseButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: _closeCoachMark,
            highlightColor: AppColors.buttonHighlightColorGray,
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100.r)),
            splashColor: AppColors.buttonHighlightColorGray.withValues(alpha: 0.3),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('닫기', style: TextStyle(color: AppColors.textColorWhite, fontSize: 14)),
            ),
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
      final response = await itemApi.getItems(ItemRequest(pageNumber: _currentPage, pageSize: _pageSize));

      if (!mounted) return;

      final feedItems = await _convertToFeedItems(response.itemPage?.content ?? []);

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
      CommonSnackBar.show(context: context, message: '피드 로딩 실패: $e', type: SnackBarType.error);
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
      final response = await itemApi.getItems(ItemRequest(pageNumber: _currentPage, pageSize: _pageSize));

      final newItems = await _convertToFeedItems(response.itemPage?.content ?? []);

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
        CommonSnackBar.show(context: context, message: '추가 피드 로딩 실패: $e', type: SnackBarType.error);
      }
    }
  }

  /// ItemDetail 리스트를 HomeFeedItem 리스트로 변환
  Future<List<HomeFeedItem>> _convertToFeedItems(List<Item> details) async {
    final feedItems = <HomeFeedItem>[];

    for (int index = 0; index < details.length; index++) {
      final d = details[index];

      // 카테고리/상태/옵션 매핑
      ItemCondition cond = ItemCondition.sealed;
      try {
        cond = item_cond.ItemCondition.values.firstWhere((e) => e.serverName == d.itemCondition);
      } catch (_) {}

      final opts = <ItemTradeOption>[];
      if (d.itemTradeOptions != null) {
        for (final s in d.itemTradeOptions!) {
          try {
            opts.add(ItemTradeOption.values.firstWhere((e) => e.serverName == s));
          } catch (_) {}
        }
      }

      // 위치 정보 변환
      String locationText = '미지정';
      if (d.latitude != null && d.longitude != null) {
        final address = await LocationService().getAddressFromCoordinates(NLatLng(d.latitude!, d.longitude!));
        if (address != null) {
          locationText = '${address.siDo} ${address.siGunGu} ${address.eupMyoenDong}';
        }
      }

      final feedItem = HomeFeedItem(
        id: index + _feedItems.length + 1,
        itemUuid: d.itemId,
        name: d.itemName ?? ' ',
        price: d.price ?? 0,
        location: locationText,
        date: d.createdDate is DateTime ? d.createdDate as DateTime : DateTime.now(),
        itemCondition: cond,
        transactionTypes: opts,
        accountStatus: d.member?.accountStatus,
        profileUrl: d.member?.profileUrl ?? '',
        likeCount: d.likeCount ?? 0,
        imageUrls: d.imageUrlList,
        description: d.itemDescription ?? '',
        hasAiAnalysis: false,
        latitude: d.latitude,
        longitude: d.longitude,
        authorMemberId: d.member?.memberId,
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
        ItemRequest(pageNumber: 0, pageSize: 10, itemStatus: ItemStatus.available.serverName),
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

  /// 카드 드롭 핸들러 (거래 요청) - 요청하기 화면으로 이동
  void _handleCardDrop(String cardId) async {
    final feedItem = _feedItems[_currentFeedIndex];

    // HomeFeedItem을 Item으로 변환
    final targetItem = Item(
      itemId: feedItem.itemUuid,
      itemName: feedItem.name,
      price: feedItem.price,
      itemCondition: feedItem.itemCondition.serverName,
      itemTradeOptions: feedItem.transactionTypes.map((e) => e.serverName).toList(),
    );

    try {
      // 거래 요청 존재 여부 확인
      final tradeApi = TradeApi();
      final exists = await tradeApi.checkTradeRequestExistence(
        TradeRequest(takeItemId: feedItem.itemUuid, giveItemId: cardId),
      );

      if (!mounted) return;

      if (exists) {
        // 거래 요청이 이미 존재하면 토스트바 표시
        CommonSnackBar.show(context: context, message: '이미 거래 요청이 존재합니다.', type: SnackBarType.error);
      } else {
        // 거래 요청이 없으면 요청 화면으로 이동
        context.navigateTo(
          screen: TradeRequestScreen(
            targetItem: targetItem,
            targetImageUrl: feedItem.imageUrls.isNotEmpty ? feedItem.imageUrls[0] : null,
            preSelectedCardId: cardId,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('거래 요청 확인 오류: $e');
      CommonSnackBar.show(context: context, message: '거래 요청 확인에 실패했습니다.', type: SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow));
    }

    // 피드 아이템이 없을 때 메시지 표시
    if (_feedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('물품이 없습니다.', style: CustomTextStyles.h3),
            const SizedBox(height: 16),
            Material(
              color: AppColors.primaryYellow,
              borderRadius: BorderRadius.circular(4.r),
              child: InkWell(
                onTap: _loadInitialItems,
                highlightColor: darkenBlend(AppColors.primaryYellow),
                splashColor: darkenBlend(AppColors.primaryYellow).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4.r),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('새로고침', style: TextStyle(color: AppColors.textColorBlack)),
                ),
              ),
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
              if (!_isLoadingMore && _hasMoreItems && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                _loadMoreItems();
              }
              return false;
            },
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              controller: _pageController,
              // 블러가 활성화된 경우 스와이프(스크롤) 동작을 비활성화해 첫 화면 고정
              physics: _isBlurShown ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
              itemCount: _feedItems.length + (_hasMoreItems ? 1 : 0),
              onPageChanged: (index) {
                // 블러가 켜져 있으면 페이지 변경 자체가 발생하지 않으므로, 여기서는 블러 OFF 상태만 처리
                if (!_isBlurShown && index < _feedItems.length) {
                  setState(() {
                    _currentFeedIndex = index;
                    // 피드 변경 시 AI 하이라이트 초기화
                    _aiHighlightedItemIds = [];
                  });
                }
              },
              itemBuilder: (context, index) {
                if (index >= _feedItems.length) {
                  // 리스트 끝에 로딩 인디케이터 표시
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow));
                }
                return HomeFeedItemWidget(
                  item: _feedItems[index],
                  showBlur: _isBlurShown,
                  // AI 추천 결과를 HomeTabScreen으로 전달
                  onAiRecommend: _onAiRecommend,
                );
              },
            ),
          ),
        ),

        // 알림 아이콘 및 메뉴 버튼
        if (!_isBlurShown)
          Positioned(
            right: 16.w,
            top: MediaQuery.of(context).padding.top + (Platform.isAndroid ? 16.h : 8.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 32.w,
                  child: OverflowBox(
                    maxWidth: 56.w,
                    maxHeight: 56.w,
                    child: Material(
                      color: AppColors.transparent,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkResponse(
                        onTap: () {
                          context.navigateTo(screen: const NotificationScreen());
                        },
                        radius: 18.w,
                        customBorder: const CircleBorder(),
                        highlightColor: AppColors.buttonHighlightColorGray.withValues(alpha: 0.5),
                        splashColor: AppColors.buttonHighlightColorGray.withValues(alpha: 0.3),
                        child: SizedBox.square(
                          dimension: 56.w,
                          child: Icon(AppIcons.alert, size: 30.sp, color: AppColors.textColorWhite),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                ReportMenuButton(
                  onReportPressed: () async {
                    if (_feedItems.isEmpty) return;
                    final currentItem = _feedItems[_currentFeedIndex];
                    final bool? reported = await context.navigateTo(
                      screen: ReportScreen(itemId: currentItem.itemUuid ?? ''),
                    );
                    if (reported == true && mounted) {
                      await CommonModal.success(
                        context: context,
                        message: '신고가 접수되었습니다.',
                        onConfirm: () => Navigator.of(context).pop(),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

        // 하단 고정 카드 덱 - AI 하이라이트 itemId 전달
        if (!_isBlurShown)
          Positioned(
            left: 0,
            right: 0,
            bottom: -130.h,
            child: HomeTabCardHand(
              cards: _myCards,
              onCardDrop: _handleCardDrop,
              highlightedItemIds: _aiHighlightedItemIds,
            ),
          )
        else
          Positioned(
            left: 0,
            right: 0,
            bottom: 10.h,
            child: SvgPicture.asset('assets/images/first-item-post-text.svg', width: 145.w),
          ),
      ],
    );
  }
}
