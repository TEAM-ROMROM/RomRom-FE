// 홈 탭 피드 위치: 목록 교체·추가·축소 시 위치 보정, 페이지 넘김 처리, 다음 페이지 준비, 광고 실패 칸 접기
part of '../home_tab_screen.dart';

mixin _HomeTabFeedPaging on _HomeTabScreenStateFields {
  /// 피드 items가 새로 교체될 때 호출 — page 0으로 점프 + 광고 슬롯 리셋 > 다음 페이지 준비.
  void _onFeedItemsReplaced(List<HomeFeedItem> feedItems) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      setState(() {
        _currentFeedIndex = 0;
        _currentVirtualIndex = 0;
        _aiHighlightedItemIds = [];
        _adSlotSchedule.reset();
        _adSlotSchedule.scheduleAdsForFeedLength(feedItems.length);
      });
      _upcomingPagePreparer.resetForReplacedFeed();
      _prepareUpcomingPages(feedItems);
    });
  }

  /// 첫 피드 도착 (이전 값 없음 > 교체·추가 분기 밖): 광고 자리 배치 > 다음 페이지 준비 (첫 광고 칸 광고 미리 요청)
  void _onInitialFeedLoaded(List<HomeFeedItem> feedItems) {
    setState(() => _adSlotSchedule.scheduleAdsForFeedLength(feedItems.length));
    _prepareUpcomingPages(feedItems);
  }

  /// 피드 items가 append될 때 (loadMore) — 광고 슬롯 추가 스케줄 > 다음 페이지 준비.
  void _onFeedItemsAppended(List<HomeFeedItem> feedItems) {
    setState(() {
      _adSlotSchedule.scheduleAdsForFeedLength(feedItems.length);
    });
    _prepareUpcomingPages(feedItems);
  }

  /// 피드 items가 줄었을 때 (신고·차단 제외) — 보던 물품(빠졌으면 다음 남은 물품) 위치로 보정, 범위 밖이면 마지막 칸으로 이동
  void _onFeedItemsRemoved(List<HomeFeedItem> previousItems, List<HomeFeedItem> nextItems) {
    final previousVirtualIndex = _currentVirtualIndex;
    // 물품 칸을 보던 중일 때만 물품 기준 보정 (광고·로딩 칸은 칸 위치 유지)
    final isViewingFeedItemPage =
        _currentVirtualIndex < _adSlotSchedule.virtualItemCount(previousItems.length) &&
        !_adSlotSchedule.isAdAtVirtualIndex(_currentVirtualIndex);
    var shouldJumpToCurrentPage = false;
    setState(() {
      if (isViewingFeedItemPage) {
        final feedIndex = resolveFeedIndexAfterRemoval(
          previousItems: previousItems,
          remainingItems: nextItems,
          previousFeedIndex: _currentFeedIndex,
        );
        _currentVirtualIndex = _adSlotSchedule.virtualIndexAtFeedIndex(feedIndex);
      }
      final isClamped = _clampCurrentPageToFeed(nextItems);
      shouldJumpToCurrentPage = isClamped || _currentVirtualIndex != previousVirtualIndex;
    });
    if (shouldJumpToCurrentPage && _pageController.hasClients) _pageController.jumpToPage(_currentVirtualIndex);
  }

  /// 페이지 넘김: 위치·본 물품 기록 > 보이는 값(광고 칸 여부·AI 하이라이트)이 바뀔 때만 재빌드 > 다음 페이지 준비
  void _onFeedPageChanged(int virtualIndex, List<HomeFeedItem> feedItems) {
    final isAdPageChanged =
        _adSlotSchedule.isAdAtVirtualIndex(_currentVirtualIndex) != _adSlotSchedule.isAdAtVirtualIndex(virtualIndex);
    if (isAdPageChanged || _aiHighlightedItemIds.isNotEmpty) {
      setState(() {
        _onFeedPageShown(virtualIndex, feedItems);
        _aiHighlightedItemIds = [];
      });
    } else {
      _onFeedPageShown(virtualIndex, feedItems);
    }
    _prepareUpcomingPages(feedItems);
  }

  /// 다음 페이지 준비: 다음 카드 첫 이미지 미리 받기 + 다음 광고 칸이 가까우면 광고 미리 요청
  void _prepareUpcomingPages(List<HomeFeedItem> feedItems) {
    _upcomingPagePreparer.prepare(
      context,
      feedItems: feedItems,
      currentFeedIndex: _currentFeedIndex,
      currentVirtualIndex: _currentVirtualIndex,
      adSlotSchedule: _adSlotSchedule,
    );
  }

  /// 목록이 줄어 현재 페이지가 물품·광고 범위를 넘으면 마지막 칸으로 보정 (setState 안에서 호출, 페이지 이동 필요 여부 반환)
  bool _clampCurrentPageToFeed(List<HomeFeedItem> feedItems) {
    final virtualItemCount = _adSlotSchedule.virtualItemCount(feedItems.length);
    final isCurrentPageOutOfRange = virtualItemCount > 0 && _currentVirtualIndex >= virtualItemCount;
    _onFeedPageShown(isCurrentPageOutOfRange ? virtualItemCount - 1 : _currentVirtualIndex, feedItems);
    // 마지막 칸이 광고면 피드 index가 갱신되지 않음 > 마지막 물품으로 보정
    if (_currentFeedIndex >= feedItems.length) _currentFeedIndex = max(0, feedItems.length - 1);
    return isCurrentPageOutOfRange;
  }

  /// 페이지 표시 처리 (setState 안에서 호출): 가상 index 저장 > 물품 칸이면 피드 index 갱신 + 본 물품 기록
  void _onFeedPageShown(int virtualIndex, List<HomeFeedItem> feedItems) {
    _currentVirtualIndex = virtualIndex;
    if (virtualIndex >= _adSlotSchedule.virtualItemCount(feedItems.length)) return;
    if (_adSlotSchedule.isAdAtVirtualIndex(virtualIndex)) return;
    final feedIndex = _adSlotSchedule.feedIndexAtVirtualIndex(virtualIndex);
    if (feedIndex >= feedItems.length) return;
    _currentFeedIndex = feedIndex;
    final uuid = feedItems[feedIndex].itemUuid;
    if (uuid != null) ref.read(homeFeedProvider.notifier).markSeen(uuid);
  }

  /// 광고 로드 실패 칸 접기: 슬롯 제거 > 앞 칸이 빠졌으면 같은 물품 유지하도록 한 페이지 당김, 보던 칸이면 다음 물품 표시
  void _collapseFailedAdSlot(int adVirtualIndex) {
    final feedItems = ref.read(homeFeedProvider).valueOrNull?.items ?? const <HomeFeedItem>[];
    if (!_adSlotSchedule.isAdAtVirtualIndex(adVirtualIndex)) return;
    final isBeforeCurrentPage = adVirtualIndex < _currentVirtualIndex;
    var shouldJumpToCurrentPage = isBeforeCurrentPage;
    setState(() {
      _adSlotSchedule.removeAdAtVirtualIndex(adVirtualIndex);
      _upcomingPagePreparer.adPreloader.removeAdSlot(adVirtualIndex);
      if (isBeforeCurrentPage) _currentVirtualIndex--;
      if (_clampCurrentPageToFeed(feedItems)) shouldJumpToCurrentPage = true;
    });
    if (shouldJumpToCurrentPage && _pageController.hasClients) {
      _pageController.jumpToPage(_currentVirtualIndex);
    }
  }
}
