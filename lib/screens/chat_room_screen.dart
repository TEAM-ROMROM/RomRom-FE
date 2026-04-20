import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:romrom_fe/enums/account_status.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/screens/chat_location_picker_screen.dart';
import 'package:romrom_fe/models/apis/objects/chat_room.dart';
import 'package:romrom_fe/models/apis/objects/chat_user_state.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/services/apis/chat_api.dart';
import 'package:romrom_fe/services/apis/image_api.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/services/chat_member_status_poller.dart';
import 'package:romrom_fe/services/chat_websocket_service.dart';
import 'package:romrom_fe/services/member_manager_service.dart';
import 'package:romrom_fe/services/notification_permission_service.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/chat_input_bar.dart';
import 'package:romrom_fe/widgets/chat_message_item.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/chat_room_app_bar.dart';
import 'package:romrom_fe/widgets/chat_trade_info_card.dart';
import 'package:romrom_fe/widgets/common/exchange_request_bottom_sheet.dart';
import 'package:romrom_fe/widgets/common/notification_bottom_sheet.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatRoomId;

  const ChatRoomScreen({super.key, required this.chatRoomId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatWebSocketService _wsService = ChatWebSocketService();
  final TextEditingController _messageController = TextEditingController();
  bool _hasText = false;
  double _inputFieldHeight = 40.0.h;

  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  StreamSubscription<ChatMessage>? _messageSubscription;

  // 낙관적 로컬 메시지(서버 응답 대기)
  final Map<String, ChatMessage> _pendingLocalMessages = {};

  // 업로드 중인 이미지 버블 ID 추적
  final Set<String> _uploadingLocalIds = {};

  // WebSocket 브로드캐스트에 imageUrls 미포함 시 REST API 보완용
  final Set<String> _pendingWsImageTempIds = {};
  Timer? _wsImageFetchTimer;

  // 이미지 선택/업로드 중복 실행 방지
  bool _isPickingImage = false;

  // 텍스트 메시지 전송 중 (서버 에코 대기)
  bool _isSendingMessage = false;

  ChatRoom chatRoom = ChatRoom();

  bool _isLoading = true;
  bool _hasError = false;
  bool _notificationSnackBarShown = false;
  bool _deleteModalShown = false;
  bool _systemMessageModalShown = false;

  bool get _hasSystemMessage => _messages.any((m) => m.type == MessageType.system);

  /// 상대방이 읽은 내 메시지 중 가장 최근 메시지 ID
  String? get _lastReadMyMessageId {
    final state = _opponentState;
    if (state == null || _myMemberId == null) return null;
    for (final msg in _messages) {
      // _messages는 reverse 순서(최신 먼저)
      if (msg.senderId != _myMemberId) continue;
      if (msg.chatMessageId == null) continue;
      if (state.isPresent) return msg.chatMessageId;
      final sentAt = msg.createdDate;
      final leftAt = state.leftAt;
      if (sentAt != null && leftAt != null && !sentAt.isAfter(leftAt)) return msg.chatMessageId;
    }
    return null;
  }

  bool get _isTradeCompleted =>
      chatRoom.tradeRequestHistory?.tradeStatus == TradeStatus.traded.serverName ||
      _messages.any((m) => m.type == MessageType.tradeCompleted);

  bool get _isInputDisabled => _hasSystemMessage || _isOpponentDeleted;

  String get _inputHintText {
    if (_hasSystemMessage) return '상대방이 채팅방을 나갔습니다';
    if (_isOpponentDeleted) return '존재하지 않거나 탈퇴한 사용자입니다';
    return '메세지를 입력하세요';
  }

  bool get _hasActiveTradeRequest {
    final latestRequestIndex = _messages.indexWhere((m) => m.type == MessageType.tradeCompleteRequest);
    return latestRequestIndex != -1 && _isActiveTradeRequest(latestRequestIndex);
  }

  // 교환 완료 액션 중복 방지
  bool _isPendingTradeAction = false;

  String _errorMessage = '';
  String? _myMemberId;

  String get _myId => _myMemberId!;
  dynamic get _opponent => chatRoom.getOpponent(_myId);
  String get _opponentNickname => chatRoom.getOpponentNickname(_myId);
  String? get _opponentId => _opponent?.memberId;
  bool get _isOpponentDeleted => _opponent?.accountStatus == AccountStatus.deleteAccount.serverName;

  final ImagePicker _picker = ImagePicker();

  // 상대방 온라인 상태
  DateTime? _opponentLastActiveAt;
  bool _isOpponentOnline = false;
  StreamSubscription? _pollerSubscription;
  Timer? _sendMessageTimeoutTimer;

  // 상대방 읽음 상태
  ChatUserState? _opponentState;
  Timer? _readStatusTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _messageController.addListener(_onMessageChanged);
  }

  bool _isLeaving = false;

  Future<void> _leaveRoom({required bool shouldPop}) async {
    if (_isLeaving) return;
    _isLeaving = true;
    try {
      // API 호출 전 구독 취소: 서버가 system 메시지를 브로드캐스트할 때 내 클라이언트가 수신하지 않도록 방지
      await _messageSubscription?.cancel();
      _messageSubscription = null;
      await ChatApi().updateChatRoomReadCursor(chatRoomId: widget.chatRoomId, isEntered: false);
    } catch (_) {
      debugPrint('채팅방 나가기 처리 실패');
    }
    if (shouldPop && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _onMessageChanged() {
    final has = _messageController.text.trim().isNotEmpty;
    if (_hasText != has && mounted) {
      setState(() => _hasText = has);
    }
    if (mounted) _updateInputFieldHeight();
  }

  void _updateInputFieldHeight() {
    // '\n' 카운트 대신 TextPainter로 실제 렌더링된 시각적 라인 수 계산.
    // ChatInputBar 레이아웃에서 TextField 가용 너비:
    //   왼쪽 패딩(16) + + 버튼(40) + 버튼 우측 갭(8) +
    //   전송 버튼 왼쪽 갭(4) + 전송 버튼(40) + 전송 오른쪽 패딩(16) +
    //   TextField contentPadding horizontal(12 * 2) = 148
    final availableWidth = MediaQuery.of(context).size.width - 148.w;
    final painter = TextPainter(
      text: TextSpan(
        text: _messageController.text.isEmpty ? ' ' : _messageController.text,
        style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w400, height: 1.2),
      ),
      textDirection: TextDirection.ltr,
      maxLines: null,
    )..layout(maxWidth: availableWidth);

    final clampedLines = painter.computeLineMetrics().length.clamp(1, 5);
    double newHeight = 40.h + ((clampedLines - 1) * 15.h);
    newHeight = newHeight.clamp(40.h, 130.h);
    if (_inputFieldHeight != newHeight && mounted) {
      setState(() => _inputFieldHeight = newHeight);
    }
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      _myMemberId = await MemberManager.getCurrentMemberId();
      if (_myMemberId == null) throw Exception('사용자 정보를 불러올 수 없습니다');

      await _wsService.connect();

      final chatApi = ChatApi();
      final response = await chatApi.getChatMessages(chatRoomId: widget.chatRoomId, pageNumber: 0, pageSize: 50);
      final opponentState = await chatApi.getChatRoomReadStatus(chatRoomId: widget.chatRoomId);
      if (!mounted) return;

      setState(() {
        chatRoom = response.chatRoom!;
        _messages = response.messages?.content ?? [];
        _opponentState = opponentState;
      });

      final opponentId = chatRoom.getOpponent(_myMemberId!)?.memberId;
      if (opponentId != null) {
        ChatMemberStatusPoller.instance.start(opponentId);
        final initialOpponent = chatRoom.getOpponent(_myMemberId!);
        setState(() {
          _opponentLastActiveAt = initialOpponent?.lastActiveAt;
          _isOpponentOnline = initialOpponent?.isOnline ?? false;
        });
        _pollerSubscription = ChatMemberStatusPoller.instance.stream.listen((member) {
          if (!mounted) return;
          setState(() {
            _opponentLastActiveAt = member.lastActiveAt;
            _isOpponentOnline = member.isOnline ?? false;
          });
        });
      }

      _messageSubscription = _wsService.subscribeToChatRoom(widget.chatRoomId).listen((newMessage) {
        debugPrint(
          '[ChatRoom] 🔔 메시지 수신: type=${newMessage.type}, id=${newMessage.chatMessageId}, senderId=${newMessage.senderId}',
        );
        if (!mounted) return;
        setState(() => _handleIncomingMessage(newMessage));
        _scrollToBottom();

        // 비속어 경고 (발신자 본인에게만 표시)
        if (newMessage.isProfanityDetected == true && newMessage.senderId == _myMemberId) {
          CommonSnackBar.show(context: context, message: '비속어 사용은 제재 대상이 될 수 있습니다.', type: SnackBarType.info);
        }

        if (newMessage.type == MessageType.system) {
          CommonModal.showOnceAfterFrame(
            context: context,
            isShown: () => _systemMessageModalShown,
            markShown: () => _systemMessageModalShown = true,
            shouldShow: () => !_deleteModalShown,
            message: '상대방이 채팅방을 나갔습니다.',
            onConfirm: () => Navigator.of(context).pop(),
          );
        }
      });

      setState(() => _isLoading = false);
      _scrollToBottom();
      chatApi.updateChatRoomReadCursor(chatRoomId: widget.chatRoomId, isEntered: true);
      // 알림 꺼진 경우 바텀시트 안내 (세션 당 1회)
      if (mounted && !_notificationSnackBarShown) {
        try {
          final bool permissionGranted = await NotificationPermissionService().isPermissionGranted();
          final memberResponse = await MemberApi().getMemberInfo();
          final bool chatNotificationAgreed = memberResponse.member?.isChatNotificationAgreed ?? true;
          if (!permissionGranted || !chatNotificationAgreed) {
            _notificationSnackBarShown = true;
            if (mounted) {
              await NotificationBottomSheet.showChatNotificationBottomSheet(context);
            }
          }
        } catch (e) {
          debugPrint('알림 권한 안내 노출 실패: $e');
        }
      }

      // 읽음 상태 주기적 갱신 (5초마다)
      _readStatusTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        if (!mounted) return;
        final state = await ChatApi().getChatRoomReadStatus(chatRoomId: widget.chatRoomId);
        if (!mounted) return;
        setState(() => _opponentState = state);
      });

      CommonModal.showOnceAfterFrame(
        context: context,
        isShown: () => _deleteModalShown,
        markShown: () => _deleteModalShown = true,
        shouldShow: () => _isOpponentDeleted,
        message: '존재하지 않거나 탈퇴한 사용자입니다.',
        onConfirm: () => Navigator.of(context).pop(),
      );
      CommonModal.showOnceAfterFrame(
        context: context,
        isShown: () => _systemMessageModalShown,
        markShown: () => _systemMessageModalShown = true,
        shouldShow: () => !_deleteModalShown && _hasSystemMessage,
        message: '상대방이 채팅방을 나갔습니다.',
        onConfirm: () => Navigator.of(context).pop(),
      );
    } catch (e) {
      debugPrint('채팅방 초기화 실패: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = ErrorUtils.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  void _handleIncomingMessage(ChatMessage newMessage) {
    debugPrint('[ChatRoom] _handleIncomingMessage: type=${newMessage.type}, id=${newMessage.chatMessageId}');
    final newId = newMessage.chatMessageId;
    final isDup = (newId != null) && _messages.any((m) => m.chatMessageId != null && m.chatMessageId == newId);
    if (isDup) {
      debugPrint('[ChatRoom] 중복 메시지 수신 무시: chatMessageId=$newId');
      return;
    }

    if (newMessage.senderId == _myMemberId && newMessage.type == MessageType.text) {
      _isSendingMessage = false;
      _sendMessageTimeoutTimer?.cancel();
    }

    // pending 로컬 메시지와 매칭 시도 (이미지 낙관적 업데이트 교체)
    String? matchedLocalId;
    if (newMessage.senderId == _myMemberId) {
      _pendingLocalMessages.forEach((localId, localMsg) {
        if (matchedLocalId != null) return;
        if (localMsg.senderId != _myMemberId) return;
        if ((localMsg.content ?? '') != (newMessage.content ?? '')) return;
        final localDt = localMsg.createdDate ?? DateTime.now();
        final serverDt = newMessage.createdDate ?? DateTime.now();
        if (serverDt.difference(localDt).inSeconds.abs() <= 10) matchedLocalId = localId;
      });
    }

    if (matchedLocalId != null) {
      final localMsg = _pendingLocalMessages.remove(matchedLocalId)!;
      final idx = _messages.indexWhere((m) => m.chatMessageId == localMsg.chatMessageId);
      final fixedServer = ChatMessage(
        chatRoomId: newMessage.chatRoomId ?? localMsg.chatRoomId,
        chatMessageId: newMessage.chatMessageId,
        senderId: newMessage.senderId ?? localMsg.senderId,
        content: (newMessage.content != null && newMessage.content!.trim().isNotEmpty)
            ? newMessage.content
            : localMsg.content,
        createdDate: newMessage.createdDate ?? localMsg.createdDate,
        type: newMessage.type ?? localMsg.type,
        imageUrls: (newMessage.imageUrls != null && newMessage.imageUrls!.isNotEmpty)
            ? newMessage.imageUrls
            : localMsg.imageUrls,
        isProfanityDetected: newMessage.isProfanityDetected,
      );
      if (idx != -1) {
        _messages[idx] = fixedServer;
      } else {
        _messages.insert(0, fixedServer);
      }
    } else {
      // WebSocket 브로드캐스트에 imageUrls 미포함 시 REST API로 보완
      if (newMessage.type == MessageType.image && (newMessage.imageUrls == null || newMessage.imageUrls!.isEmpty)) {
        final tempId = 'ws_img_${DateTime.now().microsecondsSinceEpoch}';
        _messages.insert(0, newMessage.copyWith(chatMessageId: tempId));
        _pendingWsImageTempIds.add(tempId);
        _wsImageFetchTimer?.cancel();
        _wsImageFetchTimer = Timer(const Duration(milliseconds: 500), _batchFetchWsImageUrls);
      } else {
        _messages.insert(0, newMessage);
      }
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSendingMessage || _isInputDisabled) return;

    setState(() => _isSendingMessage = true);
    _messageController.clear();

    _sendMessageTimeoutTimer?.cancel();
    _sendMessageTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isSendingMessage) {
        setState(() => _isSendingMessage = false);
        CommonSnackBar.show(context: context, message: '메시지 전송에 실패했습니다.', type: SnackBarType.error);
      }
    });

    _wsService.sendMessage(chatRoomId: widget.chatRoomId, content: content, type: MessageType.text);
  }

  Future<void> _sendImage({required List<String> imageUrls, String? imageMessage}) async {
    if (imageUrls.isEmpty || !mounted) return;

    final content = imageMessage ?? '사진을 보냈습니다.';
    final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final localMsg = ChatMessage(
      chatRoomId: widget.chatRoomId,
      chatMessageId: localId,
      senderId: _myMemberId,
      createdDate: DateTime.now(),
      content: content,
      type: MessageType.image,
      imageUrls: imageUrls,
    );
    setState(() {
      _messages.insert(0, localMsg);
      _pendingLocalMessages[localId] = localMsg;
    });
    _scrollToBottom();

    _wsService.sendMessage(
      chatRoomId: widget.chatRoomId,
      type: MessageType.image,
      content: imageMessage ?? '사진을 보냈습니다.',
      imageUrls: imageUrls,
    );
    _messageController.clear();
  }

  Future<void> _batchFetchWsImageUrls() async {
    if (_pendingWsImageTempIds.isEmpty || !mounted) return;
    try {
      final response = await ChatApi().getChatMessages(chatRoomId: widget.chatRoomId, pageNumber: 0, pageSize: 20);
      if (!mounted) return;

      final List<(String tempId, int idx, String? senderId)> pendingList = [];
      for (int i = 0; i < _messages.length; i++) {
        final id = _messages[i].chatMessageId;
        if (id != null && _pendingWsImageTempIds.contains(id)) {
          pendingList.add((id, i, _messages[i].senderId));
        }
      }

      final Map<String, List<ChatMessage>> apiImagesBySender = {};
      for (final m in response.messages?.content ?? []) {
        if (m.type != MessageType.image || m.imageUrls == null || m.imageUrls!.isEmpty) continue;
        apiImagesBySender.putIfAbsent(m.senderId ?? '', () => []).add(m);
      }

      final Map<String, List<(String tempId, int idx)>> pendingBySender = {};
      for (final p in pendingList) {
        pendingBySender.putIfAbsent(p.$3 ?? '', () => []).add((p.$1, p.$2));
      }

      setState(() {
        for (final entry in pendingBySender.entries) {
          final pending = entry.value;
          final apiMsgs = apiImagesBySender[entry.key] ?? [];
          for (int i = 0; i < pending.length && i < apiMsgs.length; i++) {
            final (tempId, idx) = pending[i];
            _messages[idx] = apiMsgs[i];
            _pendingWsImageTempIds.remove(tempId);
          }
        }
      });
    } catch (e) {
      debugPrint('[ChatRoom] WebSocket 이미지 URL 일괄 보완 실패: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });
    }
  }

  Future<void> _onPickImage() async {
    if (_isPickingImage) return;
    _isPickingImage = true;
    FocusScope.of(context).unfocus();
    try {
      final List<XFile> picked = await _picker.pickMultiImage(limit: 10);
      if (!mounted) return;
      if (picked.isEmpty) return;

      final localId = 'uploading_${DateTime.now().microsecondsSinceEpoch}';
      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            chatRoomId: widget.chatRoomId,
            chatMessageId: localId,
            senderId: _myMemberId,
            createdDate: DateTime.now(),
            content: '사진을 보냈습니다.',
            type: MessageType.image,
            imageUrls: picked.map((f) => f.path).toList(),
          ),
        );
        _uploadingLocalIds.add(localId);
      });
      _scrollToBottom();

      try {
        final uploadedImageUrls = await ImageApi().uploadImages(picked);
        if (!mounted) return;

        setState(() {
          _messages.removeWhere((m) => m.chatMessageId == localId);
          _uploadingLocalIds.remove(localId);
        });

        if (uploadedImageUrls.isEmpty) {
          CommonSnackBar.show(context: context, message: '이미지 업로드 실패', type: SnackBarType.error);
          return;
        }

        final textMessage = _messageController.text.trim();
        if (!mounted) return;
        await _sendImage(imageUrls: uploadedImageUrls, imageMessage: textMessage.isNotEmpty ? textMessage : null);
      } catch (e) {
        if (mounted) {
          setState(() {
            _messages.removeWhere((m) => m.chatMessageId == localId);
            _uploadingLocalIds.remove(localId);
          });
          CommonSnackBar.show(context: context, message: '이미지 전송에 실패했습니다: $e', type: SnackBarType.error);
        }
      }
    } catch (e) {
      if (context.mounted) {
        CommonSnackBar.show(context: context, message: '이미지 선택에 실패했습니다: $e', type: SnackBarType.error);
      }
    } finally {
      if (mounted) _isPickingImage = false;
    }
  }

  /// 위치 메시지 전송 플로우: 위치 선택 → 메시지 전송
  Future<void> _onSendLocation() async {
    if (_isInputDisabled) return;
    FocusScope.of(context).unfocus();

    final LocationAddress? result = await context.navigateTo<LocationAddress>(screen: const ChatLocationPickerScreen());

    if (result == null || !mounted) return;

    final lat = result.latitude;
    final lng = result.longitude;
    if (lat == null || lng == null) return;

    _wsService.sendMessage(
      chatRoomId: widget.chatRoomId,
      content: '위치를 보냈습니다.',
      type: MessageType.location,
      latitude: lat,
      longitude: lng,
    );
  }

  /// 교환 완료 요청 플로우: 바텀시트 → API 호출
  Future<void> _onRequestExchange() async {
    if (_isTradeCompleted || _isPendingTradeAction || _hasActiveTradeRequest) {
      CommonSnackBar.show(context: context, message: '이미 교환이 완료되었거나 요청이 진행 중입니다.', type: SnackBarType.info);
      return;
    }

    FocusScope.of(context).unfocus();

    await ExchangeRequestBottomSheet.show(
      context: context,
      chatRoom: chatRoom,
      myMemberId: _myId,
      onConfirm: _doRequestTradeCompletion,
    );
  }

  /// 교환 완료 요청 (바텀시트 확인 후 호출, fire-and-forget)
  void _doRequestTradeCompletion() {
    if (_isPendingTradeAction) return;
    setState(() => _isPendingTradeAction = true);
    debugPrint('[ChatRoom] 교환 완료 요청 API 호출 시작: chatRoomId=${widget.chatRoomId}');
    ChatApi()
        .requestTradeCompletion(chatRoomId: widget.chatRoomId)
        .then((_) {
          debugPrint('[ChatRoom] 교환 완료 요청 API 성공 → 이후 WebSocket 브로드캐스트 대기 중...');
          if (mounted) setState(() => _isPendingTradeAction = false);
        })
        .catchError((e) {
          debugPrint('[ChatRoom] 교환 완료 요청 API 실패: $e');
          if (mounted) {
            setState(() => _isPendingTradeAction = false);
            CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(e), type: SnackBarType.error);
          }
        });
  }

  Future<void> _onCancelTradeRequest() async {
    if (_isPendingTradeAction) return;
    setState(() => _isPendingTradeAction = true);
    try {
      await ChatApi().cancelTradeCompletionRequest(chatRoomId: widget.chatRoomId);
    } catch (e) {
      if (mounted) {
        CommonSnackBar.show(context: context, message: '요청 취소에 실패했습니다: $e', type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isPendingTradeAction = false);
    }
  }

  Future<void> _onRejectTradeRequest() async {
    if (_isPendingTradeAction) return;
    setState(() => _isPendingTradeAction = true);
    try {
      await ChatApi().rejectTradeCompletion(chatRoomId: widget.chatRoomId);
    } catch (e) {
      if (mounted) {
        CommonSnackBar.show(context: context, message: '거절에 실패했습니다: $e', type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isPendingTradeAction = false);
    }
  }

  Future<void> _onConfirmTradeRequest() async {
    if (_isPendingTradeAction) return;
    setState(() => _isPendingTradeAction = true);
    try {
      await ChatApi().confirmTradeCompletion(chatRoomId: widget.chatRoomId);
    } catch (e) {
      if (mounted) {
        CommonSnackBar.show(context: context, message: '교환 완료 확인에 실패했습니다: $e', type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isPendingTradeAction = false);
    }
  }

  /// 메시지 리스트에서 인덱스 [index]의 TRADE_COMPLETE_REQUEST가 아직 활성 상태인지 확인.
  /// _messages는 reverse 정렬(index 0 = 최신)이므로, 더 최신 메시지에 취소/거절/완료가 없으면 활성.
  bool _isActiveTradeRequest(int index) {
    if (_isTradeCompleted) return false;
    for (int i = 0; i < index; i++) {
      final t = _messages[i].type;
      if (t == MessageType.tradeCompleteRequestCanceled ||
          t == MessageType.tradeCompleteRequestRejected ||
          t == MessageType.tradeCompleted) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _pollerSubscription?.cancel();
    _wsImageFetchTimer?.cancel();
    _readStatusTimer?.cancel();
    if (chatRoom.chatRoomId != null) {
      _wsService.unsubscribeFromChatRoom(chatRoom.chatRoomId!);
    }
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _scrollController.dispose();
    ChatMemberStatusPoller.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primaryBlack,
        body: Center(child: CommonLoadingIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: AppColors.primaryBlack,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlack,
          leading: Material(
            color: Colors.transparent,
            child: ClipOval(
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(true),
                highlightColor: AppColors.buttonHighlightColorGray,
                splashColor: AppColors.buttonHighlightColorGray.withValues(alpha: 0.3),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(AppIcons.navigateBefore, color: AppColors.textColorWhite),
                ),
              ),
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage,
                style: CustomTextStyles.p1.copyWith(color: AppColors.textColorWhite),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Material(
                color: AppColors.primaryYellow,
                borderRadius: BorderRadius.circular(4.r),
                child: InkWell(
                  onTap: _loadInitialData,
                  customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
                  highlightColor: darkenBlend(AppColors.primaryYellow),
                  splashColor: darkenBlend(AppColors.primaryYellow).withValues(alpha: 0.3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text('다시 시도', style: CustomTextStyles.p2.copyWith(color: AppColors.primaryBlack)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _leaveRoom(shouldPop: false);
        } else {
          _leaveRoom(shouldPop: true);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.primaryBlack,
          appBar: buildChatRoomAppBar(
            context: context,
            opponentNickname: _opponentNickname,
            opponentId: _opponentId,
            isOpponentOnline: _isOpponentOnline,
            opponentLastActiveAt: _opponentLastActiveAt,
            onBackPressed: () => _leaveRoom(shouldPop: true),
            onBlockConfirm: () async {
              final opponentId = _opponentId;
              if (opponentId == null) throw Exception('상대방 정보를 찾을 수 없습니다.');
              await MemberApi().blockMember(opponentId);
              await _leaveRoom(shouldPop: true);
            },
            onLeaveChatRoomConfirm: () async {
              await ChatApi().deleteChatRoom(chatRoomId: chatRoom.chatRoomId!);
              await _leaveRoom(shouldPop: true);
            },
          ),
          body: Column(
            children: [
              ChatTradeInfoCard(chatRoom: chatRoom, myMemberId: _myId),
              Expanded(child: _buildMessageList()),
              ChatInputBar(
                controller: _messageController,
                isInputDisabled: _isInputDisabled,
                isSendingMessage: _isSendingMessage,
                hasText: _hasText,
                inputFieldHeight: _inputFieldHeight,
                hintText: _inputHintText,
                onSend: _sendMessage,
                onPickImage: _onPickImage,
                onSendLocation: _onSendLocation,
                onRequestExchange: _onRequestExchange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Text('메시지를 입력해보세요', style: CustomTextStyles.p2.copyWith(color: AppColors.opacity50White)),
      );
    }

    return ListView.builder(
      reverse: true,
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final double topGap =
            (index < _messages.length - 1 &&
                _messages[index].senderId == _messages[index + 1].senderId &&
                _messages[index].type == _messages[index + 1].type)
            ? 8.h
            : 24.h;
        final bool showTime =
            (index == 0) ||
            (index > 0 &&
                (_messages[index].senderId != _messages[index - 1].senderId ||
                    !isSameMinute(_messages[index].createdDate, _messages[index - 1].createdDate)));

        // 교환 완료 요청 활성 상태면 버튼 콜백 결정
        VoidCallback? onCancelTradeRequest;
        VoidCallback? onRejectTradeRequest;
        VoidCallback? onConfirmTradeRequest;
        if (message.type == MessageType.tradeCompleteRequest && _isActiveTradeRequest(index)) {
          if (message.senderId == _myMemberId) {
            onCancelTradeRequest = _onCancelTradeRequest;
          } else {
            onRejectTradeRequest = _onRejectTradeRequest;
            onConfirmTradeRequest = _onConfirmTradeRequest;
          }
        }

        return ChatMessageItem(
          key: ValueKey(message.chatMessageId ?? '${message.senderId}_${message.createdDate?.millisecondsSinceEpoch}'),
          message: message,
          myMemberId: _myMemberId,
          topGap: topGap,
          showTime: showTime,
          isUploading: _uploadingLocalIds.contains(message.chatMessageId),
          opponentNickname: _opponentNickname,
          showReadReceipt: message.chatMessageId != null && message.chatMessageId == _lastReadMyMessageId,
          onCancelTradeRequest: onCancelTradeRequest,
          onRejectTradeRequest: onRejectTradeRequest,
          onConfirmTradeRequest: onConfirmTradeRequest,
        );
      },
    );
  }
}
