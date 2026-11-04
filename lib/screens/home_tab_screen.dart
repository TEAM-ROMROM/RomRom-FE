import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/home_feed_refresh_result.dart';
import 'package:romrom_fe/enums/location_verification_purpose.dart';
import 'package:romrom_fe/enums/refresh_trigger.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/home_feed_item.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/providers/coach_mark_trigger_provider.dart';
import 'package:romrom_fe/providers/home_feed_provider.dart';
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/providers/notification_unread_count_provider.dart';
import 'package:romrom_fe/providers/trade_repository_provider.dart';
import 'package:romrom_fe/screens/item_register_screen.dart';
import 'package:romrom_fe/screens/notification_screen.dart';
import 'package:romrom_fe/screens/report_screen.dart';
import 'package:romrom_fe/screens/search_range_setting_screen.dart';
import 'package:romrom_fe/screens/trade_request_screen.dart';
import 'package:romrom_fe/states/home_feed_state.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/utils/home_feed_ad_slot_schedule.dart';
import 'package:romrom_fe/utils/home_feed_removal_position.dart';
import 'package:romrom_fe/utils/location_verification_gate.dart';
import 'package:romrom_fe/widgets/coach_mark/coach_mark_overlay.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/notification_permission_prompt_modal.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/common/report_menu_button.dart';
import 'package:romrom_fe/widgets/home_feed_item/home_feed_card_layout.dart';
import 'package:romrom_fe/widgets/home_feed_item_widget.dart';
import 'package:romrom_fe/widgets/home_feed_refresh_indicator.dart';
import 'package:romrom_fe/widgets/home_tab/home_feed_upcoming_page_preparer.dart';
import 'package:romrom_fe/widgets/home_tab/home_tab_empty_feed_view.dart';
import 'package:romrom_fe/widgets/home_tab/home_tab_my_items_load_error_button.dart';
import 'package:romrom_fe/widgets/home_tab/home_tab_register_button.dart';
import 'package:romrom_fe/widgets/home_tab/home_tab_top_actions.dart';
import 'package:romrom_fe/widgets/home_tab_card_hand.dart';
import 'package:romrom_fe/widgets/common/smooth_page_scroll_physics.dart';
import 'package:romrom_fe/widgets/native_ad_widget.dart';
import 'package:romrom_fe/widgets/skeletons/home_feed_skeleton.dart';

part 'home_tab/home_tab_coach_mark.dart';
part 'home_tab/home_tab_feed_paging.dart';
part 'home_tab/home_tab_actions.dart';

// 다음 페이지 선행 로드 기준: 끝에서 뷰포트 높이의 몇 배 전인지
const double loadMorePrefetchViewportRatio = 1.5;

/// 홈 피드 선행 로드 여부: 피드 자신의 세로 스크롤(depth 0)이 끝 근처일 때만
/// 카드 안 가로 이미지 캐러셀(depth 1, 가로) 알림은 제외
bool shouldPrefetchHomeFeed(ScrollMetrics metrics, int depth) {
  if (depth != 0 || metrics.axis != Axis.vertical) return false;
  final prefetchThresholdPixels = metrics.maxScrollExtent - metrics.viewportDimension * loadMorePrefetchViewportRatio;
  return metrics.pixels >= prefetchThresholdPixels;
}

/// 홈 탭 화면 — 피드 상태는 homeFeedProvider 단일 소유.
class HomeTabScreen extends ConsumerStatefulWidget {
  const HomeTabScreen({super.key, this.onLoaded});

  /// 초기 피드 로딩 완료 시 호출되는 콜백 (최초 1회).
  final Future<void> Function()? onLoaded;

  @override
  ConsumerState<HomeTabScreen> createState() => _HomeTabScreenState();
}

/// 홈 탭 화면 상태 필드 (책임별 mixin이 공유, part 파일: home_tab/)
abstract class _HomeTabScreenStateFields extends ConsumerState<HomeTabScreen> {
  final PageController _pageController = PageController();

  int _currentFeedIndex = 0;
  int _currentVirtualIndex = 0;

  OverlayEntry? _overlayEntry;

  /// AI 추천으로 하이라이트할 카드 itemId 목록 (상위 3개).
  List<String> _aiHighlightedItemIds = [];

  /// onLoaded 콜백을 정확히 1회만 부르기 위한 가드.
  bool _onLoadedFired = false;

  // 광고 슬롯 배치 (화면 로컬)
  final HomeFeedAdSlotSchedule _adSlotSchedule = HomeFeedAdSlotSchedule();

  // 다음 카드 이미지·다음 광고 칸 광고 미리 받기 (화면 종료 시 받아 둔 광고 폐기)
  final HomeFeedUpcomingPagePreparer _upcomingPagePreparer = HomeFeedUpcomingPagePreparer();

  // 빈 피드 '새로고침' 진행 중 여부 (중복 탭 차단, 버튼 스피너)
  bool _isManualRefreshInProgress = false;

  // 카드 덱 자리 '다시 시도' 진행 중 여부 (reload는 로딩 상태를 내지 않아 화면에서 추적)
  bool _isRetryingMyItems = false;
}

/// 홈 탭 화면: 피드·카드 덱·상단 버튼 구성 (코치마크·피드 위치·사용자 액션은 mixin)
class _HomeTabScreenState extends _HomeTabScreenStateFields
    with _HomeTabCoachMark, _HomeTabFeedPaging, _HomeTabActions {
  @override
  void initState() {
    super.initState();
    // 미확인 알림 배지 최신화 (개수만 조회, 첫 조회 진행 중이면 그 결과 공유)
    Future.microtask(ref.read(notificationUnreadCountProvider.notifier).refresh);
  }

  @override
  void dispose() {
    _removeCoachMarkOverlay();
    _upcomingPagePreparer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myItemsAsync = ref.watch(myItemsProvider);
    final myCards = myItemsAsync.valueOrNull?.available ?? const <Item>[];
    final isBlurShown = myItemsAsync.hasValue && myCards.isEmpty;
    // 블러 문구 분기: 교환 완료 물품만 있는 회원 / 등록 이력 없는 회원
    final hasExchangedItems = myItemsAsync.valueOrNull?.exchanged.isNotEmpty ?? false;
    // 내 물품 첫 조회 실패 (값 없음) > 카드 덱 대신 실패 안내
    final hasMyItemsLoadError = myItemsAsync.hasError && !myItemsAsync.hasValue;

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
      // onLoaded는 최초 데이터 진입 시 1회만 (첫 카드 뒤 이미지 미리 받기 함께)
      if (!_onLoadedFired && next is AsyncData<HomeFeedState>) {
        _onLoadedFired = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          _prepareUpcomingPages(next.value.items);
          await widget.onLoaded?.call();
        });
      }

      // loadMore 에러는 정상 상태 > 에러 전환 시 1회 SnackBar (목록 동일 객체여도 표시, 자동 새로고침 실패는 provider에서 swallow)
      final isNewLoadMoreError = next.hasError && next.hasValue && !(prev?.hasError ?? false);
      if (isNewLoadMoreError) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          CommonSnackBar.show(
            context: context,
            message: ErrorUtils.getErrorMessage(next.error!),
            type: SnackBarType.error,
          );
        });
      }

      final prevState = prev?.valueOrNull;
      final nextState = next.valueOrNull;
      if (prevState == null || nextState == null) return;
      final prevItems = prevState.items;
      final nextItems = nextState.items;
      if (identical(prevItems, nextItems)) return;

      // provider가 명시한 feedRevision 변화로 append/replace를 구분.
      // (위치기반 id로 list diff하던 기존 _isPrefix는 초기 페이지<10개 + refresh 시 오분류 → #904에서 폐기)
      if (nextState.feedRevision != prevState.feedRevision) {
        // refresh — 통째 교체 (page 0 점프 + 광고 슬롯 리셋)
        _onFeedItemsReplaced(nextItems);
      } else if (nextItems.length > prevItems.length) {
        // loadMore — 뒤에 append (풀 소진 되감기 포함)
        _onFeedItemsAppended(nextItems);
      } else if (nextItems.length < prevItems.length) {
        // 신고·차단 물품 제외 — 보던 물품 기준으로 위치 다시 맞춤
        _onFeedItemsRemoved(prevItems, nextItems);
      }
      // 그 외(길이·revision 불변)는 슬롯 갱신 불필요
    });

    final asyncFeed = ref.watch(homeFeedProvider);

    // 최초 로딩 (cold start) — 풀스크린 스켈레톤
    if (asyncFeed.isLoading && !asyncFeed.hasValue) {
      return const HomeFeedSkeleton();
    }

    // 첫 로드 실패 (데이터 없음) — 에러 뷰 + 다시 시도 (재시도 중엔 스켈레톤이라 중복 탭 불가)
    if (asyncFeed.hasError && !asyncFeed.hasValue) {
      return EmptyStateView.error(
        centerText: '물품을 불러오지 못했어요',
        onRetry: () => ref.read(homeFeedProvider.notifier).retryInitialLoad(),
      );
    }

    return _buildContent(
      asyncFeed: asyncFeed,
      myCards: myCards,
      isBlurShown: isBlurShown,
      hasExchangedItems: hasExchangedItems,
      hasMyItemsLoadError: hasMyItemsLoadError,
    );
  }

  Widget _buildContent({
    required AsyncValue<HomeFeedState> asyncFeed,
    required List<Item> myCards,
    required bool isBlurShown,
    required bool hasExchangedItems,
    required bool hasMyItemsLoadError,
  }) {
    final feed = asyncFeed.valueOrNull;
    // 미확인 알림 배지 (개수만 조회, 조회 실패·로딩 중엔 미표시, 배지 여부 바뀔 때만 재빌드)
    final hasUnreadNotification = ref.watch(
      notificationUnreadCountProvider.select((unreadCount) => (unreadCount.valueOrNull ?? 0) > 0),
    );
    final feedItems = feed?.items ?? const <HomeFeedItem>[];
    final hasMoreItems = feed?.hasMoreItems ?? false;
    // 새로고침 중 = 데이터는 있고 다음 로딩 중 (자동·사용자 요청 공통)
    final isRefreshing = asyncFeed.isLoading && asyncFeed.hasValue;

    if (feedItems.isEmpty) {
      return HomeTabEmptyFeedView(
        isRefreshing: _isManualRefreshInProgress || isRefreshing,
        onRefreshTap: _onEmptyFeedRefreshPressed,
        onExpandSearchRangeTap: () => context.navigateTo(screen: const SearchRangeSettingScreen()),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              // 끝에서 뷰포트 1.5배 전부터 선행 로드
              if (hasMoreItems && shouldPrefetchHomeFeed(scrollInfo.metrics, scrollInfo.depth)) {
                ref.read(homeFeedProvider.notifier).loadMore();
              }
              return false;
            },
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              controller: _pageController,
              physics: isBlurShown ? const NeverScrollableScrollPhysics() : const SmoothPageScrollPhysics(),
              itemCount: _adSlotSchedule.virtualItemCount(feedItems.length) + (hasMoreItems ? 1 : 0),
              onPageChanged: (index) {
                if (isBlurShown) return;
                _onFeedPageChanged(index, feedItems);
              },
              itemBuilder: (context, index) {
                if (index >= _adSlotSchedule.virtualItemCount(feedItems.length)) {
                  return const Center(child: CommonLoadingIndicator());
                }
                if (_adSlotSchedule.isAdAtVirtualIndex(index)) {
                  return NativeAdWidget(
                    adPreloader: _upcomingPagePreparer.adPreloader,
                    onLoadFailed: () => _collapseFailedAdSlot(index),
                  );
                }
                final feedIndex = _adSlotSchedule.feedIndexAtVirtualIndex(index);
                final feedItem = feedItems[feedIndex];
                return HomeFeedItemWidget(
                  key: ValueKey('${feedItem.itemUuid ?? feedItem.id}_$feedIndex'),
                  item: feedItem,
                  showBlur: isBlurShown,
                  hasExchangedItems: hasExchangedItems,
                  onAiRecommend: _onAiRecommend,
                );
              },
            ),
          ),
        ),

        // 상단 progress 바 (새로고침 중에만)
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
            // 신고 버튼 터치 영역 확대분만큼 위치 보정 (아이콘 시각 위치 유지)
            right: HomeFeedCardLayout.topActionsTrailingInset - ReportMenuButton.tapTargetExtraInset,
            top:
                MediaQuery.of(context).padding.top +
                HomeFeedCardLayout.topActionsTopOffset -
                ReportMenuButton.rowTopCompensation(32.w),
            child: Offstage(
              offstage: _adSlotSchedule.isAdAtVirtualIndex(_currentVirtualIndex),
              child: HomeTabTopActions(
                hasUnreadNotification: hasUnreadNotification,
                onNotificationTap: () async {
                  // 복귀 후 배지는 알림 화면 dispose의 방문 탭 읽음 > 재조회로 provider가 갱신
                  await context.navigateTo(screen: const NotificationScreen());
                },
                onReportPressed: () => _onReportPressed(feedItems),
              ),
            ),
          ),

        // 하단 카드 덱 / 내 물품 조회 실패 안내 / 등록 버튼
        if (hasMyItemsLoadError)
          Positioned(
            left: 0,
            right: 0,
            bottom: 24.h,
            child: HomeTabMyItemsLoadErrorButton(onRetryTap: _onRetryMyItemsPressed, isRetrying: _isRetryingMyItems),
          )
        else if (!isBlurShown)
          Positioned(
            left: 0,
            right: 0,
            bottom: -130.h,
            child: HomeTabCardHand(
              key: const ValueKey('home_card_hand'),
              cards: myCards,
              onCardDrop: _handleCardDrop,
              highlightedItemIds: _aiHighlightedItemIds,
              dragEnabled: !_adSlotSchedule.isAdAtVirtualIndex(_currentVirtualIndex),
            ),
          )
        else if (!_adSlotSchedule.isAdAtVirtualIndex(_currentVirtualIndex))
          Positioned(
            left: 0,
            right: 0,
            bottom: 24.h,
            child: HomeTabRegisterButton(onTap: _onRegisterButtonPressed),
          ),
      ],
    );
  }
}
