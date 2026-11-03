// 채팅방 이전 메시지 페이징: 목록 맨 위 근처 스크롤 > 다음 페이지 조회 > 목록 뒤에 붙임 (실패 시 자동 조회 멈춤 > 다시 불러오기 행)
part of '../chat_room_screen.dart';

// 목록 맨 위(오래된 쪽)에서 이 거리 안이면 이전 메시지 조회 (px)
const double _olderMessagesLoadTriggerPixels = 200;

mixin _ChatRoomOlderMessagesPaging on _ChatRoomScreenStateFields {
  /// 메시지 목록 스크롤: 맨 위(오래된 쪽) 근처 도달 시 이전 메시지 조회 (reverse 목록 > maxScrollExtent가 맨 위)
  void _onMessageListScrolled() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _olderMessagesLoadTriggerPixels) {
      _loadOlderMessages();
    }
  }

  /// 다시 불러오기 행 탭: 실패 표시 해제 > 재조회
  void _retryOlderMessages() {
    setState(() => _hasOlderMessagesLoadFailed = false);
    _loadOlderMessages();
  }

  /// 이전 메시지 한 페이지 조회: 중복 실행·끝·실패 상태면 무시 > 조회 > 목록 뒤에 붙임 (실패 시 다시 불러오기 행)
  Future<void> _loadOlderMessages() async {
    if (_isLoading || _isLoadingOlderMessages || !_hasMoreOlderMessages || _hasOlderMessagesLoadFailed) return;

    setState(() => _isLoadingOlderMessages = true);
    try {
      final response = await _chatRepository.getChatMessages(
        chatRoomId: widget.chatRoomId,
        pageNumber: _nextOlderMessagePageNumber,
        pageSize: chatMessagePageSize,
      );
      if (!mounted) return;
      setState(() {
        _messages = appendOlderMessages(current: _messages, olderMessages: response.messages?.content ?? []);
        _nextOlderMessagePageNumber++;
        _hasMoreOlderMessages = !(response.messages?.last ?? true);
      });
    } catch (e) {
      debugPrint('[ChatRoom] older messages load failed: $e');
      if (mounted) setState(() => _hasOlderMessagesLoadFailed = true);
    } finally {
      if (mounted) setState(() => _isLoadingOlderMessages = false);
    }
  }
}
