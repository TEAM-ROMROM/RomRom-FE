// 요청관리 탭 요청 목록·행동: 받은·보낸 목록 구성(차단 회원 제외), 취소·삭제, 채팅방·물품 상세 이동
part of '../request_management_tab_screen.dart';

mixin _RequestManagementRequestActions on ConsumerState<RequestManagementTabScreen> {
  // 진행 중인 취소 요청 ID (중복 탭 방지)
  final Set<String> _pendingCancelRequestIds = {};

  // 채팅방 찾는 중인 보낸 요청 ID (중복 탭 방지)
  final Set<String> _pendingChatRoomOpenRequestIds = {};

  // 완료된 요청 표시 여부 (화면 상태)
  bool get _showCompletedRequests;

  /// 로드 동안 로딩 표시 (화면 구현)
  Future<void> _runWithLoading(Future<void> Function() load);

  /// 거래 요청 취소 > 성공·실패 안내 (실패 문구 미지정 시 서버 오류 문구, 진행 중 같은 요청 무시)
  Future<void> _cancelTradeRequest(
    TradeRequestHistory request, {
    required String successMessage,
    String? failureMessage,
  }) async {
    final tradeRequestHistoryId = request.tradeRequestHistoryId ?? '';
    if (_pendingCancelRequestIds.contains(tradeRequestHistoryId)) return;
    _pendingCancelRequestIds.add(tradeRequestHistoryId);
    try {
      await ref.read(tradeRequestsProvider.notifier).cancel(tradeRequestHistoryId: tradeRequestHistoryId);
      if (mounted) CommonSnackBar.show(context: context, message: successMessage);
    } catch (error) {
      debugPrint('[request management] cancel failed : $error');
      if (!mounted) return;
      final message = failureMessage ?? ErrorUtils.getErrorMessage(error);
      CommonSnackBar.show(context: context, message: message, type: SnackBarType.error);
    } finally {
      _pendingCancelRequestIds.remove(tradeRequestHistoryId);
    }
  }

  /// 교환 완료 보낸 요청: 삭제 확인 > 삭제 (되돌릴 수 없음 > 확인 필수)
  Future<void> _confirmAndDeleteTradedRequest(TradeRequestHistory request) async {
    final isConfirmed = await context.showDeleteDialog(title: '교환 요청 삭제', description: '교환 완료된 요청을 목록에서 삭제하시겠습니까?');
    if (isConfirmed != true) return;
    await _cancelTradeRequest(request, successMessage: '삭제되었습니다.', failureMessage: '삭제에 실패했습니다');
  }

  /// 채팅 중 보낸 요청: 채팅방 찾기 > 채팅방 이동 (못 찾음 > 안내 후 상대 물품 상세, 진행 중 같은 요청 무시)
  Future<void> _openChatRoomOfSentRequest(TradeRequestHistory request) async {
    final tradeRequestHistoryId = request.tradeRequestHistoryId ?? '';
    if (_pendingChatRoomOpenRequestIds.contains(tradeRequestHistoryId)) return;
    _pendingChatRoomOpenRequestIds.add(tradeRequestHistoryId);
    try {
      final chatRoomId = await ref.read(tradeRequestsProvider.notifier).findChatRoomIdOfSentRequest(request);
      if (!mounted) return;
      if (chatRoomId == null) {
        CommonSnackBar.show(context: context, message: '채팅방을 찾지 못해 물품 상세로 이동합니다.', type: SnackBarType.info);
        _openSentRequestItemDetail(request);
        return;
      }
      context.navigateTo(screen: ChatRoomScreen(chatRoomId: chatRoomId));
    } catch (error) {
      debugPrint('[request management] chat room lookup failed : $error');
      if (!mounted) return;
      CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(error), type: SnackBarType.error);
    } finally {
      _pendingChatRoomOpenRequestIds.remove(tradeRequestHistoryId);
    }
  }

  /// 보낸 요청 상대 물품 상세 (보낸 요청 = 채팅 시작 불가)
  void _openSentRequestItemDetail(TradeRequestHistory request) {
    _openItemDetail(
      itemId: request.takeItem.itemId!,
      isMyItem: false,
      tradeRequestHistoryId: request.tradeRequestHistoryId,
      isChatAccessAllowed: false,
    );
  }

  /// 물품 상세 이동 (요청관리 진입, 첫 이미지 Hero)
  void _openItemDetail({
    required String itemId,
    required bool isMyItem,
    required bool isChatAccessAllowed,
    String? tradeRequestHistoryId,
  }) {
    context.navigateTo(
      screen: ItemDetailDescriptionScreen(
        itemId: itemId,
        imageSize: Size(MediaQuery.of(context).size.width, 400.h),
        currentImageIndex: 0,
        heroTag: 'itemImage_${itemId}_0',
        isMyItem: isMyItem,
        isRequestManagement: true,
        tradeRequestHistoryId: tradeRequestHistoryId,
        isChatAccessAllowed: isChatAccessAllowed,
      ),
    );
  }

  /// 보낸 요청 목록 (차단 회원 물품 제외, 정렬 변경 > 모든 카드 재조회, 탭: 교환 완료 > 삭제 확인, 채팅 중 > 채팅방, 그 외 > 상대 물품 상세)
  Widget _buildSentRequestsList(TradeRequestsState tradeRequests, Set<String> blockedMemberIds, bool isLoading) {
    return RequestSentList(
      sentRequests: tradeRequests.sentExcludingOpponents(blockedMemberIds),
      isLoading: isLoading,
      hasLoadFailed: tradeRequests.hasSentLoadFailed,
      onRetry: () => _runWithLoading(ref.read(tradeRequestsProvider.notifier).retrySentLoad),
      currentSort: tradeRequests.sentSortType,
      onSortChanged: (selected) {
        if (selected == tradeRequests.sentSortType) return; // 동일 정렬 재선택 시 무시
        _runWithLoading(() => ref.read(tradeRequestsProvider.notifier).changeSentSort(selected));
      },
      onCardTap: (request) {
        final tradeStatus = TradeStatus.fromServerName(request.tradeStatus);
        if (tradeStatus == TradeStatus.traded) {
          _confirmAndDeleteTradedRequest(request);
        } else if (tradeStatus == TradeStatus.chatting) {
          _openChatRoomOfSentRequest(request);
        } else {
          _openSentRequestItemDetail(request);
        }
      },
      onEditTap: (request) => TradeRequestOptionEditSheet.show(context: context, request: request),
      onCancelTap: (request) async {
        final result = await context.showDeleteDialog(
          title: '교환 요청 취소',
          description: '교환 요청을 취소하시겠습니까?',
          confirmText: '확인',
        );
        if (result == true) await _cancelTradeRequest(request, successMessage: '요청을 취소했습니다.');
      },
    );
  }

  /// 받은 요청 목록 (차단 회원 요청 제외, 완료 표시 OFF: 진행 중만, ON: 전체 / 탭 > 읽음 처리 + 요청 물품 상세 / 실패 > 현재 카드 재조회)
  Widget _buildReceivedRequestsList(
    TradeRequestsState tradeRequests,
    Set<String> blockedMemberIds, {
    required bool isLoading,
  }) {
    final receivedRequests = tradeRequests.receivedExcludingRequesters(blockedMemberIds);
    final filteredRequests = _showCompletedRequests
        ? receivedRequests
        : receivedRequests.where((request) => request.tradeStatus != TradeStatus.traded.serverName).toList();

    return RequestReceivedList(
      filteredRequests: filteredRequests,
      isLoading: isLoading,
      hasLoadFailed: tradeRequests.hasReceivedLoadFailed,
      onRetry: () => unawaited(ref.read(tradeRequestsProvider.notifier).reloadReceivedOfRequestedCard()),
      onCardTap: (request) {
        final tradeRequestHistoryId = request.tradeRequestHistoryId;
        if (tradeRequestHistoryId != null) {
          unawaited(
            ref
                .read(tradeRequestsProvider.notifier)
                .markReceivedAsRead(tradeRequestHistoryId)
                .catchError((Object error) => debugPrint('[request management] mark as read failed : $error')),
          );
        }
        _openItemDetail(
          itemId: request.giveItem.itemId!,
          isMyItem: false,
          tradeRequestHistoryId: tradeRequestHistoryId,
          isChatAccessAllowed: true, // 받은요청 = 채팅 가능
        );
      },
      onMenuTap: (request) async {
        final result = await context.showDeleteDialog(title: '교환 요청 삭제', description: '정말 삭제하시겠습니까?');
        if (result == true) await _cancelTradeRequest(request, successMessage: '요청을 삭제했습니다.');
      },
    );
  }
}
