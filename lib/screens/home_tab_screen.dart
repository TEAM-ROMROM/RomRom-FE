import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_sort_field.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/home_feed_item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/requests/trade_request.dart';
import 'package:romrom_fe/providers/coach_mark_trigger_provider.dart';
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:romrom_fe/services/apis/notification_api.dart';
import 'package:romrom_fe/services/apis/trade_api.dart';

import 'package:romrom_fe/enums/item_condition.dart' as item_cond;
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/report_menu_button.dart';
import 'package:romrom_fe/widgets/home_tab_card_hand.dart';
import 'package:romrom_fe/widgets/home_feed_item_widget.dart';
import 'package:romrom_fe/widgets/native_ad_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/icons/app_icons.dart';

import 'package:romrom_fe/services/location_service.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/screens/notification_screen.dart';
import 'package:romrom_fe/screens/report_screen.dart';
import 'package:romrom_fe/screens/item_register_screen.dart';
import 'package:romrom_fe/screens/trade_request_screen.dart';
import 'package:romrom_fe/widgets/coach_mark/coach_mark_overlay.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/skeletons/home_feed_skeleton.dart';

/// 홈 탭 화면
class HomeTabScreen extends ConsumerStatefulWidget {
  const HomeTabScreen({super.key, this.onLoaded});

  /// 초기 피드 로딩 완료 시 호출되는 콜백 (최초 1회)
  final Future<void> Function()? onLoaded;

  @override
  ConsumerState<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends ConsumerState<HomeTabScreen> {
  // 메인 콘텐츠 페이지 컨트롤러
  final PageController _pageController = PageController();
  // 피드 아이템 목록
  final List<HomeFeedItem> _feedItems = [];
  int _currentPage = 0;
  int _currentFeedIndex = 0;
  int _currentVirtualIndex = 0; // 현재 보고 있는 가상 인덱스 (광고 슬롯 판별용)
  final int _pageSize = 10;
  // 초기 로딩 상태
  bool _isLoading = false;
  // 추가 아이템 로딩 상태
  bool _isLoadingMore = false;
  // 더 로드할 아이템 여부
  bool _hasMoreItems = true;
  // 미확인 알림 존재 여부
  bool _hasUnreadNotification = false;
  // 미확인 알림 조회 중복 요청 방지
  bool _isLoadingUnreadNotification = false;
  // 오버레이 엔트리
  OverlayEntry? _overlayEntry;

  /// AI 추천으로 하이라이트할 카드 itemId 목록 (상위 3개)
  List<String> _aiHighlightedItemIds = [];

  // 초기 로드에 성공한 정렬 필드 저장
  ItemSortField _currentSortField = ItemSortField.recommended;

  @override
  void initState() {
    super.initState();
    _loadInitialItems();
    unawaited(_loadUnreadNotificationStatus());
  }

  @override
  void dispose() {
    _removeCoachMarkOverlay();
    _pageController.dispose();
    super.dispose();
  }

  /// AI 추천 결과를 받아 카드 하이라이트 상태 업데이트
  void _onAiRecommend(List<String> itemIds) {
    setState(() {
      _aiHighlightedItemIds = itemIds;
    });
    debugPrint('AI 추천 하이라이트 업데이트: $itemIds');
  }

  /// 코치마크 표시 (외부 호출용 - 첫 물건 등록 후 홈 탭에서 직접 표시)
  void showCoachMark() {
    debugPrint('====================================');
    debugPrint('HomeTabScreen.showCoachMark 호출됨');
    debugPrint('mounted: $mounted');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('코치마크 표시 시작...');
        _checkAndShowCoachMark();
      } else {
        debugPrint('⚠️ HomeTabScreen이 mounted되지 않음!');
      }
    });
    debugPrint('====================================');
  }

  /// 미확인 알림 여부 조회
  Future<void> _loadUnreadNotificationStatus() async {
    if (_isLoadingUnreadNotification) return;
    _isLoadingUnreadNotification = true;
    try {
      final response = await NotificationApi().getUnreadNotificationCount();
      if (mounted) {
        setState(() {
          _hasUnreadNotification = (response?.unReadCount ?? 0) > 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasUnreadNotification = false;
        });
      }
      debugPrint('미확인 알림 조회 실패: $e');
    } finally {
      _isLoadingUnreadNotification = false;
    }
  }

  /// 코치마크를 표시해야 하는지 체크하고 표시
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
  Future<void> _closeCoachMark() async {
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
    return CoachMarkOverlay(onClose: _closeCoachMark);
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
  /// 결과가 0개이면 recommend → distance → preferredCategory → createdDate 순으로 폴백
  Future<void> _loadInitialItems() async {
    if (!mounted || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    const fallbackOrder = [
      ItemSortField.recommended,
      ItemSortField.distance,
      ItemSortField.preferredCategory,
      ItemSortField.createdDate,
    ];

    try {
      final itemApi = ItemApi();
      List<Item> items = [];

      for (final sortField in fallbackOrder) {
        final response = await itemApi.getItems(
          ItemRequest(pageNumber: _currentPage, pageSize: _pageSize, sortField: sortField.serverName),
        );
        items = response.itemPage?.content ?? [];
        debugPrint('[HomeTab] sortField=${sortField.serverName} → ${items.length}개');
        if (items.isNotEmpty) {
          _currentSortField = sortField;
          break;
        }
      }

      if (!mounted) return;

      final feedItems = await _convertToFeedItems(items);

      setState(() {
        _feedItems
          ..clear()
          ..addAll(feedItems);
        _adVirtualIndices.clear();
        _adVirtualIndicesSorted.clear();
        _nextAdAfterFeedIndex = _adFreeCount;
        _scheduleAdsForNewItems();
        _hasMoreItems = items.isNotEmpty;
        _isLoading = false;
      });
      await widget.onLoaded?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      await widget.onLoaded?.call();

      if (!mounted) return;
      CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
    }
  }

  /// 추가 아이템 로드
  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || !_hasMoreItems) return;

    setState(() {
      _isLoadingMore = true;
      _aiHighlightedItemIds = []; // 추가 로드 시 AI 하이라이트 초기화
    });

    try {
      final itemApi = ItemApi();
      _currentPage += 1;
      var content =
          (await itemApi.getItems(
            ItemRequest(pageNumber: _currentPage, pageSize: _pageSize, sortField: _currentSortField.serverName),
          )).itemPage?.content ??
          [];

      // 끝에 도달하면 처음으로 되감아 끊김 없이 순환(또돌이표)
      if (content.isEmpty) {
        _currentPage = 0;
        content =
            (await itemApi.getItems(
              ItemRequest(pageNumber: _currentPage, pageSize: _pageSize, sortField: _currentSortField.serverName),
            )).itemPage?.content ??
            [];
      }

      final newItems = await _convertToFeedItems(content);

      setState(() {
        _feedItems.addAll(newItems);
        _scheduleAdsForNewItems();
        // 리셋 후에도 비어 있으면 전체 물품이 0개 → 순환할 게 없으므로 중단
        _hasMoreItems = content.isNotEmpty;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
      }
    }
  }

  // ─── 광고 삽입 로직 ─────────────────────────────────────────────
  // 처음 5개는 광고 없음, 이후 8~11개마다 광고 1개 (랜덤 간격)
  static const int _adFreeCount = 5;
  static const int _adMinInterval = 8;
  static const int _adMaxInterval = 11;

  final Set<int> _adVirtualIndices = {}; // O(1) 광고 슬롯 조회용
  final List<int> _adVirtualIndicesSorted = []; // adsBefore 계산을 위한 정렬 리스트
  int _nextAdAfterFeedIndex = _adFreeCount; // 다음 광고를 배치할 실제 피드 아이템 인덱스
  final Random _random = Random();

  /// 광고 포함 가상 총 슬롯 수
  int get _virtualItemCount => _feedItems.length + _adVirtualIndices.length;

  /// 해당 가상 인덱스가 광고 슬롯인지 여부
  bool _isAdAtVirtualIndex(int vi) => _adVirtualIndices.contains(vi);

  /// 가상 인덱스 → 실제 피드 아이템 인덱스 변환 (광고 슬롯에서 호출 금지)
  int _feedIndexAtVirtualIndex(int vi) {
    int adsBefore = 0;
    for (final ai in _adVirtualIndicesSorted) {
      if (ai > vi) break;
      adsBefore++;
    }
    return vi - adsBefore;
  }

  /// 새 피드 아이템이 추가된 후 광고 슬롯 위치를 랜덤으로 스케줄링.
  /// _feedItems 갱신 직후 setState 내에서 호출해야 함.
  void _scheduleAdsForNewItems() {
    while (_nextAdAfterFeedIndex < _feedItems.length) {
      final vi = _nextAdAfterFeedIndex + _adVirtualIndices.length;
      _adVirtualIndices.add(vi);
      _adVirtualIndicesSorted.add(vi); // 오름차순 보장 (vi는 단조 증가)
      _nextAdAfterFeedIndex += _adMinInterval + _random.nextInt(_adMaxInterval - _adMinInterval + 1);
    }
  }
  // ────────────────────────────────────────────────────────────────

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
        CommonSnackBar.show(context: context, message: '이미 교환 요청이 존재합니다.', type: SnackBarType.error);
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
      CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
    }
  }

  // 공유 기능은 공용 유틸로 대체됨: `shareItem(itemId: ...)`

  @override
  Widget build(BuildContext context) {
    final myItemsAsync = ref.watch(myItemsProvider);
    final myCards = myItemsAsync.value?.available ?? const <Item>[];
    // 최초 로드 전(value==null)에는 블러 판정 보류 → 깜빡임 방지
    final isBlurShown = myItemsAsync.hasValue && myCards.isEmpty;

    // 등록 탭의 첫 물건 등록 신호를 수신해 코치마크 표시 (GlobalKey 직접 호출 대체)
    // postFrameCallback으로 감싸 build 중 setState 경고 방지
    ref.listen<bool>(coachMarkTriggerProvider, (prev, next) {
      if (next == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(coachMarkTriggerProvider.notifier).consume();
          showCoachMark();
        });
      }
    });

    if (_isLoading) {
      return const HomeFeedSkeleton();
    }
    return _buildContent(myCards: myCards, isBlurShown: isBlurShown);
  }

  Widget _buildContent({required List<Item> myCards, required bool isBlurShown}) {
    // 피드 아이템이 없을 때 메시지 표시
    if (_feedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('물품이 없습니다.', style: CustomTextStyles.h3),
            const SizedBox(height: 16),
            AppPressable(
              onTap: _loadInitialItems,
              scaleDown: AppPressable.scaleButton,
              enableRipple: false,
              child: Material(
                color: AppColors.primaryYellow,
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
              physics: isBlurShown ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
              itemCount: _virtualItemCount + (_hasMoreItems ? 1 : 0),
              onPageChanged: (index) {
                // 블러가 켜져 있으면 페이지 변경 자체가 발생하지 않으므로, 여기서는 블러 OFF 상태만 처리
                if (!isBlurShown) {
                  setState(() {
                    _currentVirtualIndex = index;
                    // 광고 슬롯이 아닐 때만 현재 피드 인덱스 갱신
                    if (index < _virtualItemCount && !_isAdAtVirtualIndex(index)) {
                      _currentFeedIndex = _feedIndexAtVirtualIndex(index);
                    }
                    // 피드 변경 시 AI 하이라이트 초기화 (로딩 인디케이터 페이지 포함)
                    _aiHighlightedItemIds = [];
                  });
                }
              },
              itemBuilder: (context, index) {
                // 로딩 인디케이터 (맨 끝)
                if (index >= _virtualItemCount) {
                  return const Center(child: CommonLoadingIndicator());
                }
                // 광고 슬롯
                if (_isAdAtVirtualIndex(index)) {
                  return const NativeAdWidget();
                }
                // 일반 피드 아이템
                final feedIndex = _feedIndexAtVirtualIndex(index);
                final feedItem = _feedItems[feedIndex];
                return HomeFeedItemWidget(
                  // 순환 시 같은 itemUuid가 중복되므로 위치(feedIndex)까지 포함해 키 유일성 보장
                  key: ValueKey('${feedItem.itemUuid ?? feedItem.id}_$feedIndex'),
                  item: feedItem,
                  showBlur: isBlurShown,
                  // AI 추천 결과를 HomeTabScreen으로 전달
                  onAiRecommend: _onAiRecommend,
                );
              },
            ),
          ),
        ),

        // 알림 아이콘 및 메뉴 버튼 - 광고 슬롯에서는 숨김
        if (!isBlurShown && !_isAdAtVirtualIndex(_currentVirtualIndex))
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
                        onTap: () async {
                          await context.navigateTo(screen: const NotificationScreen());
                          if (!mounted) return;
                          _loadUnreadNotificationStatus();
                        },
                        radius: 18.w,
                        customBorder: const CircleBorder(),
                        highlightColor: AppColors.buttonHighlightColorGray.withValues(alpha: 0.5),
                        splashColor: AppColors.buttonHighlightColorGray.withValues(alpha: 0.3),
                        child: SizedBox.square(
                          dimension: 56.w,
                          child: Center(
                            child: _hasUnreadNotification
                                ? SvgPicture.asset('assets/images/alertWithBadge.svg', width: 30.w, height: 30.w)
                                : Icon(AppIcons.alert, size: 30.w, color: AppColors.textColorWhite),
                          ),
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

        // 하단 고정 카드 덱
        if (!isBlurShown)
          Positioned(
            left: 0,
            right: 0,
            bottom: -130.h,
            child: HomeTabCardHand(
              key: const ValueKey('home_card_hand'),
              cards: myCards,
              onCardDrop: _handleCardDrop,
              highlightedItemIds: _aiHighlightedItemIds,
              dragEnabled: !_isAdAtVirtualIndex(_currentVirtualIndex),
            ),
          )
        else if (!_isAdAtVirtualIndex(_currentVirtualIndex))
          Positioned(
            left: 0,
            right: 0,
            bottom: 24.h,
            child: Center(
              child: AppPressable(
                onTap: () async {
                  final result = await context.navigateTo<Map<String, dynamic>>(
                    screen: ItemRegisterScreen(onClose: () => Navigator.pop(context)),
                  );
                  if (!mounted) return;
                  if (result is Map<String, dynamic> && result['isFirstItemPosted'] == true) {
                    showCoachMark(); // 목록 갱신은 provider(myItemsProvider)가 자동 처리
                  }
                },
                scaleDown: AppPressable.scaleButton,
                enableRipple: false,
                child: Container(
                  width: 123.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: const [BoxShadow(color: AppColors.opacity20Black, blurRadius: 4, offset: Offset(0, 4))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 24.sp, color: AppColors.primaryBlack),
                      SizedBox(width: 4.w),
                      Text(
                        '등록하기',
                        style: CustomTextStyles.h3.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryBlack),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
