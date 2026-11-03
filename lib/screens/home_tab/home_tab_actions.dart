// 홈 탭 사용자 액션: AI 추천 하이라이트, 카드 드롭 교환 요청, 빈 피드 새로고침, 내 물품 다시 시도, 신고, 등록
part of '../home_tab_screen.dart';

mixin _HomeTabActions on _HomeTabScreenStateFields, _HomeTabCoachMark {
  void _onAiRecommend(List<String> itemIds) {
    setState(() {
      _aiHighlightedItemIds = itemIds;
    });
    debugPrint('AI 추천 하이라이트 업데이트: $itemIds');
  }

  Future<void> _handleCardDrop(String cardId) async {
    final feed = ref.read(homeFeedProvider).valueOrNull;
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
      final exists = await ref
          .read(tradeRepositoryProvider)
          .hasTradeRequest(takeItemId: feedItem.itemUuid, giveItemId: cardId);

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

  /// 빈 피드 새로고침: 중복 탭 차단 > 30초 제한 없이 조회 > 실패·여전히 비어 있음 안내
  Future<void> _onEmptyFeedRefreshPressed() async {
    if (_isManualRefreshInProgress) return;
    setState(() => _isManualRefreshInProgress = true);
    try {
      final refreshResult = await ref.read(homeFeedProvider.notifier).refresh(trigger: RefreshTrigger.manualRefresh);
      if (!mounted) return;
      final isFeedStillEmpty = ref.read(homeFeedProvider).valueOrNull?.items.isEmpty ?? true;
      if (refreshResult == HomeFeedRefreshResult.failed) {
        CommonSnackBar.show(context: context, message: '새로고침하지 못했어요. 잠시 후 다시 시도해 주세요.', type: SnackBarType.error);
      } else if (refreshResult == HomeFeedRefreshResult.refreshed && isFeedStillEmpty) {
        CommonSnackBar.show(context: context, message: '아직 보여 드릴 물품이 없어요.', type: SnackBarType.info);
      }
    } finally {
      if (mounted) setState(() => _isManualRefreshInProgress = false);
    }
  }

  /// 카드 덱 자리 다시 시도: 진행 중이면 무시 > 내 물품 재조회
  Future<void> _onRetryMyItemsPressed() async {
    if (_isRetryingMyItems) return;
    setState(() => _isRetryingMyItems = true);
    try {
      await ref.read(myItemsProvider.notifier).reload();
    } finally {
      if (mounted) setState(() => _isRetryingMyItems = false);
    }
  }

  /// 현재 카드 신고: 신고 화면 > 접수되면 피드에서 제외 + 완료 안내
  Future<void> _onReportPressed(List<HomeFeedItem> feedItems) async {
    if (_currentFeedIndex >= feedItems.length) return;
    final reportedItemId = feedItems[_currentFeedIndex].itemUuid;
    if (reportedItemId == null) return;
    final bool? reported = await context.navigateTo(screen: ReportScreen.item(itemId: reportedItemId));
    if (reported == true && mounted) {
      ref.read(homeFeedProvider.notifier).excludeReportedItem(reportedItemId);
      await CommonModal.success(
        context: context,
        message: '신고가 접수되었습니다.',
        onConfirm: () => Navigator.of(context).pop(),
      );
    }
  }

  /// 블러 상태 등록 버튼: 등록 화면 > 첫 등록이면 코치마크
  Future<void> _onRegisterButtonPressed() async {
    final result = await context.navigateTo<Map<String, dynamic>>(
      screen: ItemRegisterScreen(onClose: () => Navigator.pop(context)),
    );
    if (!mounted) return;
    if (result is Map<String, dynamic> && result['isFirstItemPosted'] == true) {
      showCoachMark();
    }
  }
}
