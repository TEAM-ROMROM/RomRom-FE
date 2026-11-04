// 채팅방 입력 편의: 방별 임시 저장 글 복원·저장, 입력 높이, 포커스, 빠른 답장 넣기 (전송 안 함)
part of '../chat_room_screen.dart';

mixin _ChatRoomInputConvenience on _ChatRoomScreenStateFields {
  final FocusNode _messageFocusNode = FocusNode();
  bool _isMessageInputFocused = false;
  // 임시 저장 notifier (initState에서 보관 > 입력마다 ref 조회 없음)
  late final ChatInputDraftNotifier _chatInputDraftNotifier;

  bool get _shouldShowQuickReplies => shouldShowQuickReplies(
    isInputDisabled: _isInputDisabled,
    isInputFocused: _isMessageInputFocused,
    inputText: _messageController.text,
  );

  /// 입력 편의 시작 (initState): 임시 저장 글 복원 > 입력·포커스 변경 구독
  void _startInputConvenience() {
    _chatInputDraftNotifier = ref.read(chatInputDraftProvider.notifier);
    final draft = _chatInputDraftNotifier.draftOf(widget.chatRoomId);
    if (draft.isNotEmpty) {
      _messageController.value = TextEditingValue(
        text: draft,
        selection: TextSelection.collapsed(offset: draft.length),
      );
      _hasText = draft.trim().isNotEmpty;
      // 입력 높이 계산에 화면 너비 필요 > 첫 프레임 뒤
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateInputFieldHeight();
      });
    }
    _messageController.addListener(_onMessageChanged);
    _messageFocusNode.addListener(_onMessageFocusChanged);
  }

  /// 입력 편의 해제 (dispose, 컨트롤러 해제 전)
  void _stopInputConvenience() {
    _messageController.removeListener(_onMessageChanged);
    _messageFocusNode.removeListener(_onMessageFocusChanged);
    _messageFocusNode.dispose();
  }

  /// 입력 변경: 전송 버튼 활성 > 임시 저장 (빈 글 > 삭제) > 입력 높이
  void _onMessageChanged() {
    final has = _messageController.text.trim().isNotEmpty;
    if (_hasText != has && mounted) {
      setState(() => _hasText = has);
    }
    _chatInputDraftNotifier.saveDraft(chatRoomId: widget.chatRoomId, text: _messageController.text);
    if (mounted) _updateInputFieldHeight();
  }

  void _updateInputFieldHeight() {
    final newHeight = ChatInputBar.calculateInputFieldHeight(
      text: _messageController.text,
      screenWidth: MediaQuery.sizeOf(context).width,
    );
    if (_inputFieldHeight != newHeight && mounted) {
      setState(() => _inputFieldHeight = newHeight);
    }
  }

  void _onMessageFocusChanged() {
    final isFocused = _messageFocusNode.hasFocus;
    if (_isMessageInputFocused != isFocused && mounted) setState(() => _isMessageInputFocused = isFocused);
  }

  /// 빠른 답장 탭: 입력창에 문구 넣기 (커서 끝, 전송 안 함)
  void _onQuickReplySelected(String phrase) {
    _messageController.value = applyQuickReplyToInput(currentValue: _messageController.value, phrase: phrase);
  }
}
