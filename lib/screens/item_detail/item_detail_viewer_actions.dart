// 물품 보는 사람 액션: 닫기, 공유, 판매자 프로필, 거래 장소 지도, 신고, 좋아요, 채팅하기, 요청하기
part of '../item_detail_description_screen.dart';

mixin _ItemDetailViewerActions on _ItemDetailDescriptionScreenStateFields {
  void _popWithLikeResult() {
    Navigator.of(context).pop();
  }

  Future<void> _shareItem() async {
    final itemId = item?.itemId;
    if (itemId == null) return;
    try {
      final RenderBox? box = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      final Rect? origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
      debugPrint('ItemDetail: sharing itemId=$itemId origin=$origin');
      await shareItem(itemId: itemId, sharePositionOrigin: origin);
      debugPrint('ItemDetail: share completed for itemId=$itemId');
    } catch (e, st) {
      debugPrint('ItemDetail: share failed for itemId=$itemId - $e\n$st');
      if (mounted) CommonSnackBar.show(context: context, message: '공유에 실패했습니다.', type: SnackBarType.error);
    }
  }

  void _openSellerProfile() {
    if (item?.member?.memberId != null) {
      context.navigateTo(screen: MemberProfileScreen(memberId: item!.member!.memberId!));
    }
  }

  void _openTradeLocationDetail() {
    if (item?.latitude != null && item?.longitude != null) {
      context.navigateTo(
        screen: TradeLocationDetailScreen(latitude: item!.latitude!, longitude: item!.longitude!),
      );
    }
  }

  /// 신고: 신고 화면 > 접수 시 완료 모달 > 상세 닫기
  Future<void> _openReportScreen() async {
    final bool? isReported = await context.navigateTo(screen: ReportScreen.item(itemId: widget.itemId));

    if (isReported == true && mounted) {
      await CommonModal.success(
        context: context,
        message: '신고가 접수되었습니다.',
        onConfirm: () {
          Navigator.of(context).pop();
          _popWithLikeResult();
        },
      );
    }
  }

  void _toggleLike() {
    final id = item?.itemId;
    if (id == null || id.isEmpty) return;

    // 본인글 차단은 toggle 내부에서 동기 처리 — await 없이 즉시 하트 반응
    ref.read(itemLikeProvider.notifier).toggle(id, authorMemberId: item?.member?.memberId);
  }

  /// 채팅하기(받은 요청 수락 = 거래 시작): 진행 중이면 무시 > GPS 동네 인증 > 채팅방 생성 > 목록 갱신 > 채팅방 이동
  Future<void> _handleChatButtonPressed() async {
    if (_isChatCreationInProgress) return;
    if (item == null || widget.tradeRequestHistoryId == null) {
      CommonSnackBar.show(context: context, message: '채팅방을 생성할 수 없습니다', type: SnackBarType.error);
      return;
    }
    final isLocationVerified = await ref
        .read(locationVerificationGateProvider)
        .ensureVerified(context, purpose: LocationVerificationPurpose.chatStart);
    if (!mounted || !isLocationVerified) return;

    setState(() => _isChatCreationInProgress = true);
    try {
      // 1. 채팅방 생성 + 채팅 목록 재조회 (이미 있으면 기존 방 반환, chatRoomsProvider 경유)
      final chatRoom = await ref
          .read(chatRoomsProvider.notifier)
          .createRoom(opponentMemberId: item!.member!.memberId!, tradeRequestHistoryId: widget.tradeRequestHistoryId!);

      if (!mounted) return;

      // 2. 채팅방 화면으로 이동
      context.navigateTo(screen: ChatRoomScreen(chatRoomId: chatRoom.chatRoomId!));
    } catch (e) {
      debugPrint('채팅방 생성 실패: $e');
      if (!mounted) return;
      // 서버 동네 인증 거부 > 인증 안내로 이동 (오류 안내 생략)
      final gate = ref.read(locationVerificationGateProvider);
      if (await gate.recoverFromServerRejection(context, e, purpose: LocationVerificationPurpose.chatStart)) return;
      if (!mounted) return;
      CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
    } finally {
      // 버튼 잠금 해제 (성공·실패 공통)
      if (mounted) setState(() => _isChatCreationInProgress = false);
    }
  }

  /// 요청하기: GPS 동네 인증 > 교환 요청 화면
  Future<void> _navigateToRequestScreen() async {
    if (item == null) return;
    final isLocationVerified = await ref
        .read(locationVerificationGateProvider)
        .ensureVerified(context, purpose: LocationVerificationPurpose.tradeRequest);
    if (!mounted || !isLocationVerified || item == null) return;

    context.navigateTo(
      screen: TradeRequestScreen(targetItem: item!, targetImageUrl: imageUrls.isNotEmpty ? imageUrls[0] : null),
    );
  }
}
