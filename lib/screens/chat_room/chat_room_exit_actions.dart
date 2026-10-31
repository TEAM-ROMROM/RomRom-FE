// 채팅방 나가기 흐름: 퇴장 처리(구독 취소 > 읽음 커서 퇴장), 상대 차단 후 나가기, 방 삭제 후 나가기
part of '../chat_room_screen.dart';

mixin _ChatRoomExitActions on _ChatRoomScreenStateFields {
  Future<void> _leaveRoom({required bool shouldPop}) async {
    if (_isLeaving) return;
    _isLeaving = true;
    try {
      // API 호출 전 구독 취소: 서버가 system 메시지를 브로드캐스트할 때 내 클라이언트가 수신하지 않도록 방지
      await _messageSubscription?.cancel();
      _messageSubscription = null;
      await _chatRepository.updateChatRoomReadCursor(chatRoomId: widget.chatRoomId, isEntered: false);
    } catch (_) {
      debugPrint('채팅방 나가기 처리 실패');
    }
    if (shouldPop && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  /// 상대 차단: memberBlockProvider 경유 (실패 시 provider가 롤백·에러 안내, 방 유지) > 안내 > 방 나가기
  Future<void> _blockOpponentAndLeave() async {
    final opponentId = _opponentId;
    if (opponentId == null) throw Exception('상대방 정보를 찾을 수 없습니다.');
    final isBlockSucceeded = await ref.read(memberBlockProvider.notifier).setBlocked(opponentId, true);
    if (!isBlockSucceeded) return;
    if (context.mounted) {
      CommonSnackBar.show(context: context, message: '사용자를 차단했습니다', type: SnackBarType.success);
    }
    await _leaveRoom(shouldPop: true);
  }

  /// 방 삭제: chatRoomsProvider 경유 (API > 채팅 목록 재조회) > 방 나가기
  Future<void> _deleteRoomAndLeave() async {
    await ref.read(chatRoomsProvider.notifier).deleteRoom(chatRoom.chatRoomId!);
    await _leaveRoom(shouldPop: true);
  }
}
