import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/enums/refresh_trigger.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/trade_request.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/home_feed_item.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/providers/coach_mark_trigger_provider.dart';
import 'package:romrom_fe/providers/home_feed_provider.dart';
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/screens/item_register_screen.dart';
import 'package:romrom_fe/screens/notification_screen.dart';
import 'package:romrom_fe/screens/report_screen.dart';
import 'package:romrom_fe/screens/trade_request_screen.dart';
import 'package:romrom_fe/services/apis/notification_api.dart';
import 'package:romrom_fe/services/apis/trade_api.dart';
import 'package:romrom_fe/states/home_feed_state.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/coach_mark/coach_mark_overlay.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/common/report_menu_button.dart';
import 'package:romrom_fe/widgets/home_feed_item_widget.dart';
import 'package:romrom_fe/widgets/home_feed_refresh_indicator.dart';
import 'package:romrom_fe/widgets/home_tab_card_hand.dart';
import 'package:romrom_fe/widgets/native_ad_widget.dart';
import 'package:romrom_fe/widgets/skeletons/home_feed_skeleton.dart';

/// 홈 탭 화면 — 피드 상태는 homeFeedProvider 단일 소유.
class HomeTabScreen extends ConsumerStatefulWidget {
  const HomeTabScreen({super.key, this.onLoaded});

  /// 초기 피드 로딩 완료 시 호출되는 콜백 (최초 1회).
  final Future<void> Function()? onLoaded;

  @override
  ConsumerState<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends ConsumerState<HomeTabScreen> {
  final PageController _pageController = PageController();

  int _currentFeedIndex = 0;
  int _currentVirtualIndex = 0;

  bool _hasUnreadNotification = false;
  bool _isLoadingUnreadNotification = false;

  OverlayEntry? _overlayEntry;

  /// AI 추천으로 하이라이트할 카드 itemId 목록 (상위 3개).
  List<String> _aiHighlightedItemIds = [];

  /// onLoaded 콜백을 정확히 1회만 부르기 위한 가드.
  bool _onLoadedFired = false;

  // ─── 광고 슬롯 (화면 로컬) ─────────────────────────────────────────
  static const int _adFreeCount = 5;
  static const int _adMinInterval = 8;
  static const int _adMaxInterval = 11;

  final Set<int> _adVirtualIndices = {};
  final List<int> _adVirtualIndicesSorted = [];
  int _nextAdAfterFeedIndex = _adFreeCount;
  final Random _random = Random();

  int _virtualItemCount(int feedLen) => feedLen + _adVirtualIndices.length;
  bool _isAdAtVirtualIndex(int vi) => _adVirtualIndices.contains(vi);

  int _feedIndexAtVirtualIndex(int vi) {
    int adsBefore = 0;
    for (final ai in _adVirtualIndicesSorted) {
      if (ai > vi) break;
      adsBefore++;
    }
    return vi - adsBefore;
  }

  void _resetAdSlots() {
    _adVirtualIndices.clear();
    _adVirtualIndicesSorted.clear();
    _nextAdAfterFeedIndex = _adFreeCount;
  }

  void _scheduleAdsForFeedLength(int feedLen) {
    while (_nextAdAfterFeedIndex < feedLen) {
      final vi = _nextAdAfterFeedIndex + _adVirtualIndices.length;
      _adVirtualIndices.add(vi);
      _adVirtualIndicesSorted.add(vi);
      _nextAdAfterFeedIndex += _adMinInterval + _random.nextInt(_adMaxInterval - _adMinInterval + 1);
    }
  }
  // ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    unawaited(_loadUnreadNotificationStatus());
  }

  @override
  void dispose() {
    _removeCoachMarkOverlay();
    _pageController.dispose();
    super.dispose();
  }

  void _onAiRecommend(List<String> itemIds) {
    setState(() {
      _aiHighlightedItemIds = itemIds;
    });
    debugPrint('AI 추천 하이라이트 업데이트: $itemIds');
  }

  /// 코치마크 표시 (외부 호출용 — 첫 물건 등록 후 홈 탭에서 직접 표시).
  void showCoachMark() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndShowCoachMark();
      }
    });
  }

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

  Future<void> _checkAndShowCoachMark() async {
    try {
      final userInfo = UserInfo();
      await userInfo.getUserInfo();
      final bool shouldShowCoachMark = (userInfo.isFirstItemPosted == true) && (userInfo.isCoachMarkShown != true);
      if (shouldShowCoachMark) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showCoachMarkOverlay();
        });
      }
    } catch (e) {
      debugPrint('⚠️ 코치마크 체크 실패: $e');
    }
  }

  Future<void> _closeCoachMark() async {
    _removeCoachMarkOverlay();
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
  }

  void _showCoachMarkOverlay() {
    _removeCoachMarkOverlay();
    _overlayEntry = OverlayEntry(builder: (context) => CoachMarkOverlay(onClose: _closeCoachMark));
    if (mounted && _overlayEntry != null) {
      try {
        Overlay.of(context).insert(_overlayEntry!);
      } on FlutterError catch (e) {
        debugPrint('오버레이 삽입 오류: $e');
        _overlayEntry = null;
      } catch (e) {
        debugPrint('오버레이 삽입 알 수 없는 오류: $e');
        _overlayEntry = null;
      }
    }
  }

  void _removeCoachMarkOverlay() {
    if (_overlayEntry != null) {
      try {
        _overlayEntry!.remove();
      } catch (e) {
        debugPrint('오류: 오버레이 제거 실패 - $e');
      }
      _overlayEntry = null;
    }
  }

  /// 피드 items가 새로 교체될 때 호출 — page 0으로 점프 + 광고 슬롯 리셋.
  void _onFeedItemsReplaced(int newLen) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      setState(() {
        _currentFeedIndex = 0;
        _currentVirtualIndex = 0;
        _aiHighlightedItemIds = [];
        _resetAdSlots();
        _scheduleAdsForFeedLength(newLen);
      });
    });
  }

  /// 피드 items가 append될 때 (loadMore) — 광고 슬롯만 추가 스케줄.
  void _onFeedItemsAppended(int newLen) {
    setState(() {
      _scheduleAdsForFeedLength(newLen);
    });
  }

  Future<void> _handleCardDrop(String cardId) async {
    final feed = ref.read(homeFeedProvider).value;
    if (feed == null || feed.items.isEmpty) return;
    if (_currentFeedIndex >= feed.items.length) return;

    final feedItem = feed.items[_currentFeedIndex];
    final targetItem = Item(
      itemId: feedItem.itemUuid,
      itemName: feedItem.name,
      price: feedItem.price,
      itemCondition: feedItem.itemCondition.serverName,
      itemTradeOptions: feedItem.transactionTypes.map((e) => e.serverName).toList(),
    );

    try {
      final tradeApi = TradeApi();
      final exists = await tradeApi.checkTradeRequestExistence(
        TradeRequest(takeItemId: feedItem.itemUuid, giveItemId: cardId),
      );

      if (!mounted) return;

      if (exists) {
        CommonSnackBar.show(context: context, message: '이미 교환 요청이 존재합니다.', type: SnackBarType.error);
      } else {
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

  bool _isPrefix(List<HomeFeedItem> shorter, List<HomeFeedItem> longer) {
    if (shorter.length > longer.length) return false;
    for (int i = 0; i < shorter.length; i++) {
      if (!identical(shorter[i], longer[i]) && shorter[i].id != longer[i].id) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final myItemsAsync = ref.watch(myItemsProvider);
    final myCards = myItemsAsync.value?.available ?? const <Item>[];
    final isBlurShown = myItemsAsync.hasValue && myCards.isEmpty;

    // 등록 탭의 첫 물건 등록 신호 → 코치마크 표시
    ref.listen<bool>(coachMarkTriggerProvider, (prev, next) {
      if (next == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(coachMarkTriggerProvider.notifier).consume();
          showCoachMark();
        });
      }
    });

    // 피드 상태 변경 감지 → page 0 점프 + 광고 슬롯 리셋
    ref.listen<AsyncValue<HomeFeedState>>(homeFeedProvider, (prev, next) {
      // onLoaded는 최초 데이터 진입 시 1회만
      if (!_onLoadedFired && next is AsyncData<HomeFeedState>) {
        _onLoadedFired = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await widget.onLoaded?.call();
        });
      }

      final prevItems = prev?.value?.items;
      final nextItems = next.value?.items;
      if (prevItems == null || nextItems == null) return;
      if (identical(prevItems, nextItems)) return;

      // 길이만 늘었고 앞쪽이 동일 → append (loadMore)
      if (nextItems.length > prevItems.length && _isPrefix(prevItems, nextItems)) {
        _onFeedItemsAppended(nextItems.length);
      } else {
        // 그 외 — 새로고침 등으로 통째 교체
        _onFeedItemsReplaced(nextItems.length);
      }

      // loadMore 등에서 발생한 에러는 SnackBar로 표시 (자동 새로고침 silent fail은 provider에서 swallow됨)
      if (next.hasError && next.hasValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          CommonSnackBar.show(
            context: context,
            message: ErrorUtils.getErrorMessage(next.error!),
            type: SnackBarType.error,
          );
        });
      }
    });

    final asyncFeed = ref.watch(homeFeedProvider);

    // 최초 로딩 (cold start) — 풀스크린 스켈레톤
    if (asyncFeed.isLoading && !asyncFeed.hasValue) {
      return const HomeFeedSkeleton();
    }

    return _buildContent(asyncFeed: asyncFeed, myCards: myCards, isBlurShown: isBlurShown);
  }

  Widget _buildContent({
    required AsyncValue<HomeFeedState> asyncFeed,
    required List<Item> myCards,
    required bool isBlurShown,
  }) {
    final feed = asyncFeed.value;
    final feedItems = feed?.items ?? const <HomeFeedItem>[];
    final hasMoreItems = feed?.hasMoreItems ?? false;
    // 자동 새로고침 중 = 데이터는 있고 다음 로딩 중
    final isRefreshing = asyncFeed.isLoading && asyncFeed.hasValue;

    if (feedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('물품이 없습니다.', style: CustomTextStyles.h3),
            const SizedBox(height: 16),
            AppPressable(
              onTap: () => ref.read(homeFeedProvider.notifier).refresh(trigger: RefreshTrigger.tabReentry),
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
              if (hasMoreItems && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                ref.read(homeFeedProvider.notifier).loadMore();
              }
              return false;
            },
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              controller: _pageController,
              physics: isBlurShown ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
              itemCount: _virtualItemCount(feedItems.length) + (hasMoreItems ? 1 : 0),
              onPageChanged: (index) {
                if (isBlurShown) return;
                setState(() {
                  _currentVirtualIndex = index;
                  if (index < _virtualItemCount(feedItems.length) && !_isAdAtVirtualIndex(index)) {
                    _currentFeedIndex = _feedIndexAtVirtualIndex(index);
                    final uuid = feedItems[_currentFeedIndex].itemUuid;
                    if (uuid != null) {
                      ref.read(homeFeedProvider.notifier).markSeen(uuid);
                    }
                  }
                  _aiHighlightedItemIds = [];
                });
              },
              itemBuilder: (context, index) {
                if (index >= _virtualItemCount(feedItems.length)) {
                  return const Center(child: CommonLoadingIndicator());
                }
                if (_isAdAtVirtualIndex(index)) {
                  return const NativeAdWidget();
                }
                final feedIndex = _feedIndexAtVirtualIndex(index);
                final feedItem = feedItems[feedIndex];
                return HomeFeedItemWidget(
                  key: ValueKey('${feedItem.itemUuid ?? feedItem.id}_$feedIndex'),
                  item: feedItem,
                  showBlur: isBlurShown,
                  onAiRecommend: _onAiRecommend,
                );
              },
            ),
          ),
        ),

        // 상단 progress 바 (자동 새로고침 중에만)
        Positioned(
          top: MediaQuery.of(context).padding.top,
          left: 0,
          right: 0,
          child: HomeFeedRefreshIndicator(visible: isRefreshing),
        ),

        // 알림 아이콘 및 메뉴 버튼 - 광고 슬롯에서는 Offstage로 숨김(트리에서 제거하지 않음)
        // 조건부 if로 제거하면 Stack children 개수가 바뀌어 형제인 HomeTabCardHand가 remount되고
        // 펼침(팬) 애니메이션이 다시 재생됨 → Offstage로 element를 유지해 children 개수를 고정한다.
        if (!isBlurShown)
          Positioned(
            right: 16.w,
            top: MediaQuery.of(context).padding.top + (Platform.isAndroid ? 16.h : 8.h),
            child: Offstage(
              offstage: _isAdAtVirtualIndex(_currentVirtualIndex),
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
                      if (feedItems.isEmpty) return;
                      final currentItem = feedItems[_currentFeedIndex];
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
          ),

        // 하단 카드 덱 / 등록 버튼
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
                    showCoachMark();
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
