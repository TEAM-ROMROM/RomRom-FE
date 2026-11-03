import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:romrom_fe/enums/account_status.dart';
import 'package:romrom_fe/enums/chat_recommended_action.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/models/apis/objects/chat_action_recommendation.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/screens/chat_location_picker_screen.dart';
import 'package:romrom_fe/models/apis/objects/chat_room.dart';
import 'package:romrom_fe/models/apis/objects/chat_user_state.dart';
import 'package:romrom_fe/repositories/chat_repository.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/utils/chat_message_send_rules.dart';
import 'package:romrom_fe/utils/chat_room_message_rules.dart';
import 'package:romrom_fe/utils/image_compressor.dart';
import 'package:romrom_fe/services/chat_member_status_poller.dart';
import 'package:romrom_fe/services/chat_websocket_service.dart';
import 'package:romrom_fe/services/member_manager_service.dart';
import 'package:romrom_fe/services/notification_permission_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/providers/chat_recommendation_provider.dart';
import 'package:romrom_fe/providers/chat_repository_provider.dart';
import 'package:romrom_fe/providers/chat_rooms_provider.dart';
import 'package:romrom_fe/providers/image_repository_provider.dart';
import 'package:romrom_fe/providers/member_block_provider.dart';
import 'package:romrom_fe/providers/member_profile_provider.dart';
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/chat_input_bar.dart';
import 'package:romrom_fe/widgets/common/error_scaffold.dart';
import 'package:romrom_fe/widgets/chat_room/chat_recommendation_banner.dart';
import 'package:romrom_fe/widgets/chat_room/chat_room_message_list.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/chat_room_app_bar.dart';
import 'package:romrom_fe/widgets/chat_trade_info_card.dart';
import 'package:romrom_fe/widgets/common/exchange_request_bottom_sheet.dart';
import 'package:romrom_fe/widgets/common/notification_bottom_sheet.dart';
import 'package:romrom_fe/screens/trade_review_screen.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';

part 'chat_room/chat_room_messaging.dart';
part 'chat_room/chat_room_trade_actions.dart';
part 'chat_room/chat_room_attachment_sending.dart';
part 'chat_room/chat_room_exit_actions.dart';
part 'chat_room/chat_room_recommendation_actions.dart';
part 'chat_room/chat_room_initial_load.dart';
part 'chat_room/chat_room_older_messages_paging.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String chatRoomId;
  final bool autoTriggerExchangeRequest;

  const ChatRoomScreen({super.key, required this.chatRoomId, this.autoTriggerExchangeRequest = false});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

/// 채팅방 화면 상태 필드·파생 값 (책임별 mixin이 공유, part 파일: chat_room/)
abstract class _ChatRoomScreenStateFields extends ConsumerState<ChatRoomScreen> {
  final ChatWebSocketService _wsService = ChatWebSocketService();
  final TextEditingController _messageController = TextEditingController();
  bool _hasText = false;
  double _inputFieldHeight = 40.0.h;

  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  StreamSubscription<ChatMessage>? _messageSubscription;

  // 재연결 동기화 중복 실행 방지
  bool _isResyncing = false;
  // 재연결 이벤트 구독
  StreamSubscription<void>? _reconnectSubscription;

  // 교환 완료 요청 낙관적 업데이트용 로컬 임시 메시지 ID
  String? _latestLocalTradeRequestId;

  // 낙관적 로컬 메시지(서버 응답 대기, 실패 표시 포함)
  final Map<String, ChatMessage> _pendingLocalMessages = {};

  // 전송 실패 로컬 메시지 ID (말풍선에 다시 보내기·삭제 표시)
  final Set<String> _failedLocalMessageIds = {};

  // 로컬 메시지별 서버 에코 대기 타이머 (초과 시 실패 표시)
  final Map<String, Timer> _sendEchoTimeoutTimers = {};

  // 다시 보내기로 대체된 원래 메시지 (서버에 늦게 저장된 경우 그 에코를 흡수해 중복 표시 방지)
  final Map<String, ChatMessage> _supersededLocalMessages = {};

  // 이전 메시지 페이징: 다음 조회 페이지, 남은 페이지 여부, 조회 중, 실패(자동 조회 멈춤 > 다시 불러오기 행)
  int _nextOlderMessagePageNumber = 1;
  bool _hasMoreOlderMessages = false;
  bool _isLoadingOlderMessages = false;
  bool _hasOlderMessagesLoadFailed = false;

  // 업로드 중인 이미지 버블 ID 추적
  final Set<String> _uploadingLocalIds = {};

  // WebSocket 브로드캐스트에 imageUrls 미포함 시 REST API 보완용
  final Set<String> _pendingWsImageTempIds = {};
  Timer? _wsImageFetchTimer;

  // 이미지 선택/업로드 중복 실행 방지
  bool _isPickingImage = false;

  // 텍스트 전송 잠금: 실패 아닌 대기 텍스트가 남았는지 (전송 상태에서 매번 계산 > 해제 누락 없음)
  bool get _isSendingMessage => hasPendingTextAwaitingEcho(
    pendingLocalMessages: _pendingLocalMessages,
    failedLocalMessageIds: _failedLocalMessageIds,
  );

  ChatRoom chatRoom = ChatRoom();

  bool _isLoading = true;
  bool _hasError = false;
  bool _notificationSnackBarShown = false;
  bool _deleteModalShown = false;
  bool _systemMessageModalShown = false;

  bool get _hasSystemMessage => _messages.any((m) => m.type == MessageType.system);

  /// 상대방이 읽은 내 메시지 중 가장 최근 메시지 ID
  String? get _lastReadMyMessageId =>
      findLastReadMyMessageId(messages: _messages, myMemberId: _myMemberId, opponentState: _opponentState);

  bool get _isTradeCompleted =>
      chatRoom.tradeRequestHistory?.tradeStatus == TradeStatus.traded.serverName ||
      _messages.any((m) => m.type == MessageType.tradeCompleted);

  bool get _isInputDisabled => _hasSystemMessage || _isOpponentDeleted;

  String get _inputHintText {
    if (_hasSystemMessage) return '상대방이 채팅방을 나갔습니다';
    if (_isOpponentDeleted) return '존재하지 않거나 탈퇴한 사용자입니다';
    return '메세지를 입력하세요';
  }

  bool get _hasActiveTradeRequest => hasActiveTradeRequest(messages: _messages, isTradeCompleted: _isTradeCompleted);

  // 교환 완료 액션 중복 방지
  bool _isPendingTradeAction = false;

  // 후기 화면 중복 진입 방지 (수락자가 이미 진입한 경우 WebSocket tradeCompleted 무시)
  bool _reviewNavigated = false;

  // 후기 화면 열림 여부 (확인 API·소켓 완료 동시 도착, 후기 쓰기 연타 시 1개만)
  bool _isTradeReviewScreenOpen = false;

  // 이번 진입에서 후기 작성 완료 여부 (완료 카드 '후기 쓰기' 숨김, 서버 작성 여부 필드 없음)
  bool _hasWrittenReviewInThisVisit = false;

  // 완료 카드 '후기 쓰기' 노출 여부 (거래 기록 ID 있고 이번 진입에서 아직 안 씀)
  bool get _canWriteReview =>
      chatRoom.tradeRequestHistory?.tradeRequestHistoryId != null && !_hasWrittenReviewInThisVisit;

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

  // 상대방 읽음 상태
  ChatUserState? _opponentState;
  StreamSubscription<ChatUserState>? _readEventSubscription;

  // AI 행동 추천 이벤트 구독 (추천 상태는 chatRecommendationProvider 소유)
  StreamSubscription<ChatActionRecommendation>? _recommendationSubscription;

  // 채팅 API 접근 (핸들러 전용, build에서 사용 안 함)
  ChatRepository get _chatRepository => ref.read(chatRepositoryProvider);

  // 방 나가기 중복 실행 방지
  bool _isLeaving = false;
}

/// 채팅방 화면: 수명주기·입력 높이·화면 구성 (로직은 mixin 7개: 송수신, 이전 메시지 페이징, 교환 액션, 첨부, 나가기, AI 추천, 초기화)
class _ChatRoomScreenState extends _ChatRoomScreenStateFields
    with
        WidgetsBindingObserver,
        _ChatRoomMessaging,
        _ChatRoomOlderMessagesPaging,
        _ChatRoomTradeActions,
        _ChatRoomAttachmentSending,
        _ChatRoomExitActions,
        _ChatRoomRecommendationActions,
        _ChatRoomInitialLoad {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
    _messageController.addListener(_onMessageChanged);
    _scrollController.addListener(_onMessageListScrolled);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // 잠금화면 또는 background 진입 시 퇴장 처리 → isPresent=false
      unawaited(
        _chatRepository
            .updateChatRoomReadCursor(chatRoomId: widget.chatRoomId, isEntered: false)
            .catchError((e) => debugPrint('[ChatRoom] paused read-cursor 업데이트 실패: $e')),
      );
    } else if (state == AppLifecycleState.resumed) {
      // foreground 복귀 시 재입장 처리 → isPresent=true
      unawaited(_chatRepository.updateChatRoomReadCursor(chatRoomId: widget.chatRoomId, isEntered: true));
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
    final newHeight = ChatInputBar.calculateInputFieldHeight(
      text: _messageController.text,
      screenWidth: MediaQuery.of(context).size.width,
    );
    if (_inputFieldHeight != newHeight && mounted) {
      setState(() => _inputFieldHeight = newHeight);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageSubscription?.cancel();
    _readEventSubscription?.cancel();
    _reconnectSubscription?.cancel();
    _wsService.unsubscribeFromReadEvents(widget.chatRoomId);
    _recommendationSubscription?.cancel();
    _wsService.unsubscribeFromRecommendations(widget.chatRoomId);
    _pollerSubscription?.cancel();
    _wsImageFetchTimer?.cancel();
    for (final timer in _sendEchoTimeoutTimers.values) {
      timer.cancel();
    }
    if (chatRoom.chatRoomId != null) {
      _wsService.unsubscribeFromChatRoom(chatRoom.chatRoomId!);
    }
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _scrollController.removeListener(_onMessageListScrolled);
    _scrollController.dispose();
    ChatMemberStatusPoller.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ChatActionRecommendation? currentRecommendation = ref.watch(
      chatRecommendationProvider.select((state) => state.recommendationOf(widget.chatRoomId)),
    );

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primaryBlack,
        body: Center(child: CommonLoadingIndicator()),
      );
    }

    if (_hasError) {
      return ErrorScaffold(
        message: _errorMessage,
        onBackPressed: () => Navigator.of(context).pop(true),
        onRetry: _loadInitialData,
      );
    }

    return PopScope(
      canPop: false,
      // 시스템 뒤로 가기: 이미 pop됐으면 퇴장 처리만, 아니면 퇴장 처리 후 pop
      onPopInvokedWithResult: (didPop, result) => _leaveRoom(shouldPop: !didPop),
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
            onBlockConfirm: _blockOpponentAndLeave,
            onLeaveChatRoomConfirm: _deleteRoomAndLeave,
          ),
          body: Column(
            children: [
              ChatTradeInfoCard(chatRoom: chatRoom, myMemberId: _myId),
              Expanded(
                child: ChatRoomMessageList(
                  messages: _messages,
                  scrollController: _scrollController,
                  myMemberId: _myMemberId,
                  opponentNickname: _opponentNickname,
                  uploadingMessageIds: _uploadingLocalIds,
                  pendingLocalMessageIds: _pendingLocalMessages.keys.toSet(),
                  failedLocalMessageIds: _failedLocalMessageIds,
                  isLoadingOlderMessages: _isLoadingOlderMessages,
                  hasOlderMessagesLoadFailed: _hasOlderMessagesLoadFailed,
                  onRetryOlderMessages: _retryOlderMessages,
                  lastReadMyMessageId: _lastReadMyMessageId,
                  isTradeCompleted: _isTradeCompleted,
                  isTradeActionPending: _isPendingTradeAction,
                  onCancelTradeRequest: _onCancelTradeRequest,
                  onRejectTradeRequest: _onRejectTradeRequest,
                  onConfirmTradeRequest: _onConfirmTradeRequest,
                  onRetryFailedMessage: _retryFailedMessage,
                  onDeleteFailedMessage: _deleteFailedMessage,
                  onWriteReview: _canWriteReview ? _openTradeReviewScreen : null,
                ),
              ),
              ChatRecommendationBanner(
                action: _resolveVisibleRecommendedAction(currentRecommendation),
                onActionPressed: _onRecommendedActionPressed,
                onDismissed: _onRecommendationDismissed,
              ),
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
}
