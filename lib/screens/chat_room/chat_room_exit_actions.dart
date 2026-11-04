// 채팅방 나가기 흐름: 퇴장 처리(구독 해제 > 읽음 커서 퇴장 > 화면 닫기), 상대 차단 후 나가기, 방 삭제 후 나가기
part of '../chat_room_screen.dart';

mixin _ChatRoomExitActions on _ChatRoomScreenStateFields, _ChatRoomMessaging {
  /// 방 나가기: 안 읽음 해제 > 메시지 구독 해제 > 퇴장 커서 (같은 방 다른 화면 열려 있으면 생략) > 화면 닫기
  /// [hasRoomListChanged] true > pop(true)로 채팅 목록 재조회 신호 (차단 등 목록에 영향 있는 변경만)
  Future<void> _leaveRoom({required bool shouldPop, bool hasRoomListChanged = false}) async {
    if (_isLeaving) return;
    _isLeaving = true;
    // 방 안에서 읽은 메시지가 목록 구독으로 안 읽음에 쌓인 것 해제 (탭바 배지 정확도, await 전 > dispose 후 ref 사용 방지)
    if (mounted) ref.read(chatRoomsProvider.notifier).markRoomAsRead(widget.chatRoomId);
    // API 호출 전 구독 해제: 서버가 system 메시지를 브로드캐스트할 때 이 화면이 수신하지 않게
    _stopRoomMessageSubscription();
    // 같은 방 화면이 아래에 남아 있으면 퇴장 전송 안 함 (남은 화면 접속 상태 유지)
    if (!_openChatRoomRegistry.hasOtherOpenScreen(chatRoomId: widget.chatRoomId, owner: this)) {
      try {
        await _chatRepository.updateChatRoomReadCursor(chatRoomId: widget.chatRoomId, isEntered: false);
      } catch (error) {
        debugPrint('[ChatRoom] leave read cursor update failed : $error');
      }
    }
    if (shouldPop && mounted) _popChatRoomScreen(result: hasRoomListChanged ? true : null);
  }

  /// 상대 차단: memberBlockProvider 경유 (실패 시 provider가 롤백·에러 안내, 방 유지) > 안내 > 방 나가기
  Future<void> _blockOpponentAndLeave() async {
    final opponentId = _opponentId;
    if (opponentId == null) throw Exception('상대방 정보를 찾을 수 없습니다.');
    final isBlockSucceeded = await ref.read(memberBlockProvider.notifier).setBlocked(opponentId, true);
    if (!mounted) return;
    if (!isBlockSucceeded) {
      _closeRoutesAboveChatRoom();
      return;
    }
    CommonSnackBar.show(context: context, message: '사용자를 차단했습니다', type: SnackBarType.success);
    await _leaveRoom(shouldPop: true, hasRoomListChanged: true);
  }

  /// 방 삭제: 구독 해제 > chatRoomsProvider 경유 삭제 (API > 목록 재조회) > 방 나가기
  /// 삭제 실패 > 구독 복구·놓친 메시지 재조회 후 예외 전달 (확인 모달이 안내)
  Future<void> _deleteRoomAndLeave() async {
    // 삭제 전 구독 해제: 서버 나감 방송을 이 화면이 받지 않게 ('상대방이 나갔습니다' 오표시 방지)
    _stopRoomMessageSubscription();
    try {
      await ref.read(chatRoomsProvider.notifier).deleteRoom(chatRoom.chatRoomId!);
    } catch (error) {
      if (mounted) {
        _startRoomMessageSubscription();
        unawaited(_resyncMessages());
      }
      rethrow;
    }
    await _leaveRoom(shouldPop: true);
  }

  /// 채팅방 화면 닫기: 위에 뜬 모달·시트 먼저 닫고 이 화면 pop (이미 닫힌 화면이면 무시)
  void _popChatRoomScreen({Object? result}) {
    final chatRoomRoute = ModalRoute.of(context);
    if (chatRoomRoute == null || !chatRoomRoute.isActive) return;
    _closeRoutesAboveChatRoom();
    Navigator.of(context).pop(result);
  }

  /// 이 화면 위에 뜬 모달·시트 닫기 (방 유지)
  void _closeRoutesAboveChatRoom() {
    final chatRoomRoute = ModalRoute.of(context);
    if (chatRoomRoute == null || !chatRoomRoute.isActive) return;
    Navigator.of(context).popUntil((route) => route == chatRoomRoute);
  }
}
