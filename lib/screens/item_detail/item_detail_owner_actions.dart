// 내 물품 관리: 상태 변경(교환 가능 <-> 교환 완료), 수정, 삭제
part of '../item_detail_description_screen.dart';

mixin _ItemDetailOwnerActions on _ItemDetailDescriptionScreenStateFields, _ItemDetailLoading {
  /// 상태 변경 메뉴: 교환 가능 > 교환 상대 선택 > 채팅방(교환 완료 요청 자동, 등록 탭과 같은 흐름) > 돌아오면 상세 재조회
  /// 교환 완료 > 확인 후 교환 가능으로
  Future<void> _onChangeStatusPressed(Item item) async {
    if (item.itemStatus == ItemStatus.available.serverName) {
      final chatRoomId = await context.navigateTo<String>(screen: TradeCompletePartnerSelectScreen(item: item));
      if (!mounted || chatRoomId == null) return;
      await context.navigateTo(screen: ChatRoomScreen(chatRoomId: chatRoomId, autoTriggerExchangeRequest: true));
      // 채팅방에서 교환 완료됐을 수 있음 > 오래된 상태(메뉴·요청 버튼) 방지
      if (mounted) await _loadItemDetail();
      return;
    }

    final isConfirmed = await context.showDeleteDialog(
      title: '교환 가능으로 변경',
      description: '교환 가능으로 변경하시겠습니까?',
      confirmText: '확인',
    );
    if (isConfirmed != true || !mounted) return;
    await _changeItemStatusToAvailable(item);
  }

  /// 교환 완료 > 교환 가능: 중복 요청 차단 > 상태 변경(myItemsProvider) > 성공 안내 후 상세 닫기(true)
  Future<void> _changeItemStatusToAvailable(Item item) async {
    if (_isStatusChangeInProgress) return;
    if (item.itemId == null) {
      CommonSnackBar.show(context: context, message: '물품 정보를 찾을 수 없어요', type: SnackBarType.error);
      return;
    }

    _isStatusChangeInProgress = true;
    try {
      final request = ItemRequest(itemId: item.itemId, itemStatus: ItemStatus.available.serverName);
      await ref.read(myItemsProvider.notifier).changeStatus(request);
      if (!mounted) return;
      CommonSnackBar.show(context: context, message: '교환 가능으로 변경되었습니다');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
      }
    } finally {
      // (성공·실패 공통)
      _isStatusChangeInProgress = false;
    }
  }

  /// 수정: 수정 화면 > 변경됐으면 상세 재조회
  Future<void> _openItemModification() async {
    final modificationResult = await context.navigateTo<Map<String, dynamic>>(
      screen: ItemModificationScreen(itemId: item?.itemId!, onClose: () => Navigator.pop(context)),
    );
    if (modificationResult != null && modificationResult['updated'] == true && mounted) {
      _loadItemDetail();
    }
  }

  /// 삭제: 확인 모달 > 삭제(myItemsProvider) > 성공 안내 후 상세 닫기(true)
  Future<void> _confirmAndDeleteItem() async {
    final isConfirmed = await context.showItemDeleteConfirmDialog();
    if (isConfirmed != true) return;

    final itemId = item!.itemId;
    if (itemId == null) {
      if (mounted) CommonSnackBar.show(context: context, message: '물품 정보를 찾을 수 없어요', type: SnackBarType.error);
      return;
    }

    try {
      await ref.read(myItemsProvider.notifier).delete(itemId);
      if (!mounted) return;
      CommonSnackBar.show(context: context, message: '물품이 삭제되었습니다');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
      }
    }
  }
}
