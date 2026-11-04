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
import 'package:romrom_fe/screens/report_screen.dart';
import 'package:romrom_fe/models/apis/objects/chat_room.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/models/apis/objects/chat_user_state.dart';
import 'package:romrom_fe/repositories/chat_repository.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/utils/chat_message_action_rules.dart';
import 'package:romrom_fe/utils/chat_message_send_rules.dart';
import 'package:romrom_fe/utils/chat_room_live_message_rules.dart';
import 'package:romrom_fe/utils/camera_permission_helper.dart';
import 'package:romrom_fe/utils/chat_input_convenience_rules.dart';
import 'package:romrom_fe/utils/chat_room_message_rules.dart';
import 'package:romrom_fe/utils/chat_room_unread_rules.dart';
import 'package:romrom_fe/utils/image_compressor.dart';
import 'package:romrom_fe/utils/reverse_list_scroll_to_item.dart';
import 'package:romrom_fe/utils/widget_instance_cache.dart';
import 'package:romrom_fe/services/chat_member_status_poller.dart';
import 'package:romrom_fe/services/chat_websocket_service.dart';
import 'package:romrom_fe/services/member_manager_service.dart';
import 'package:romrom_fe/services/notification_permission_service.dart';
import 'package:romrom_fe/services/open_chat_room_registry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/providers/chat_input_draft_provider.dart';
import 'package:romrom_fe/providers/chat_notification_guide_provider.dart';
import 'package:romrom_fe/providers/chat_recommendation_provider.dart';
import 'package:romrom_fe/providers/chat_repository_provider.dart';
import 'package:romrom_fe/providers/chat_rooms_provider.dart';
import 'package:romrom_fe/providers/image_repository_provider.dart';
import 'package:romrom_fe/providers/member_block_provider.dart';
import 'package:romrom_fe/providers/member_profile_provider.dart';
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/providers/open_chat_room_registry_provider.dart';
import 'package:romrom_fe/providers/trade_requests_provider.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/chat_input_bar.dart';
import 'package:romrom_fe/widgets/common/error_scaffold.dart';
import 'package:romrom_fe/widgets/chat_room/chat_appointment_proposal_sheet.dart';
import 'package:romrom_fe/widgets/chat_room/chat_connection_banner.dart';
import 'package:romrom_fe/widgets/chat_room/chat_image_send_preview_sheet.dart';
import 'package:romrom_fe/widgets/chat_room/chat_quick_reply_bar.dart';
import 'package:romrom_fe/widgets/chat_room/chat_recommendation_banner.dart';
import 'package:romrom_fe/widgets/chat_room/chat_room_message_list.dart';
import 'package:romrom_fe/widgets/chat_room/chat_scroll_to_latest_button.dart';
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
part 'chat_room/chat_room_header.dart';
part 'chat_room/chat_room_scroll_to_bottom.dart';
part 'chat_room/chat_room_new_message_indicator.dart';
part 'chat_room/chat_room_unread_position.dart';
part 'chat_room/chat_room_input_convenience.dart';
part 'chat_room/chat_room_message_actions.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String chatRoomId;
  final bool autoTriggerExchangeRequest;
  // 진입 시 안 읽음 수 (채팅 목록은 진입 전 0으로 초기화 > 목록이 전달, 없으면 목록 상태에서 조회)
  final int? unreadCountAtEntry;

  const ChatRoomScreen({
    super.key,
    required this.chatRoomId,
    this.autoTriggerExchangeRequest = false,
    this.unreadCountAtEntry,
  });

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

  // 진입 시 안 읽은 첫 메시지 ID ('여기까지 읽었어요' 위치, 내가 보내면 숨김)
  String? _firstUnreadMessageId;

  // 진입 조회 중(실패 화면 포함) 소켓으로 받은 메시지 (조회 결과와 중복 제거 후 반영)
  final List<ChatMessage> _liveMessagesDuringInitialLoad = [];

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
  bool _deleteModalShown = false;
  bool _systemMessageModalShown = false;
  // 내가 이 방 알림을 끈 상태 (메시지 조회 응답 > 메뉴 토글로 갱신)
  bool _isNotificationMuted = false;

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

  // 내 후기 작성 여부 (진입 시 서버 isReviewWrittenByMe, 구버전 서버 > false, 작성 완료 시 true)
  bool _isReviewWrittenByMe = false;

  // 완료 카드 '후기 쓰기' 노출 여부 (거래 기록 ID 있고 아직 안 씀)
  bool get _canWriteReview => chatRoom.tradeRequestHistory?.tradeRequestHistoryId != null && !_isReviewWrittenByMe;

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

  // 열린 채팅방 화면 목록 (initState에서 보관 > dispose 중 ref 사용 없이 해제)
  late final OpenChatRoomRegistry _openChatRoomRegistry;
  bool _isRegisteredAsOpenChatRoom = false;

  /// 채팅방 메시지 소켓 구독 시작 (이미 구독 중이면 무시, 구현: _ChatRoomInitialLoad)
  void _startRoomMessageSubscription();

  /// 채팅방 메시지 소켓 구독 해제 (구독 안 했으면 무시, 구현: _ChatRoomInitialLoad)
  void _stopRoomMessageSubscription();

  /// 읽음 커서 갱신 (기다리지 않음, 실패는 로그만 > 다음 진입·복귀 때 다시 갱신)
  void _updateReadCursorInBackground({required bool isEntered}) {
    unawaited(
      _chatRepository
          .updateChatRoomReadCursor(chatRoomId: widget.chatRoomId, isEntered: isEntered)
          .catchError(
            (Object error) => debugPrint('[ChatRoom] read cursor update failed (entered: $isEntered) : $error'),
          ),
    );
  }
}

/// 채팅방 화면: 수명주기·화면 구성 (로직은 mixin 13개: 맨 아래 스크롤, 새 메시지 알림, 송수신, 이전 메시지 페이징, 안 읽은 위치, 교환 액션, 첨부, 나가기, 메시지 확장 동작, 상단 캐시, AI 추천, 입력 편의, 초기화)
class _ChatRoomScreenState extends _ChatRoomScreenStateFields
    with
        WidgetsBindingObserver,
        _ChatRoomScrollToBottom,
        _ChatRoomNewMessageIndicator,
        _ChatRoomMessaging,
        _ChatRoomOlderMessagesPaging,
        _ChatRoomUnreadPosition,
        _ChatRoomTradeActions,
        _ChatRoomAttachmentSending,
        _ChatRoomExitActions,
        _ChatRoomMessageActions,
        _ChatRoomHeader,
        _ChatRoomRecommendationActions,
        _ChatRoomInputConvenience,
        _ChatRoomInitialLoad {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _openChatRoomRegistry = ref.read(openChatRoomRegistryProvider);
    _captureUnreadCountAtEntry();
    _startInputConvenience();
    _loadInitialData();
    _scrollController.addListener(_onMessageListScrolled);
    _scrollController.addListener(_onScrollPositionChangedForLatestButton);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 열린 채팅방 등록 1회 (맨 위 판정에 route 필요 > initState 다음 시점)
    if (_isRegisteredAsOpenChatRoom) return;
    _isRegisteredAsOpenChatRoom = true;
    final chatRoomRoute = ModalRoute.of(context);
    _openChatRoomRegistry.register(
      owner: this,
      chatRoomId: widget.chatRoomId,
      isRouteCurrent: () => chatRoomRoute?.isCurrent ?? false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // 잠금화면 또는 background 진입 시 퇴장 처리 → isPresent=false
      _updateReadCursorInBackground(isEntered: false);
    } else if (state == AppLifecycleState.resumed) {
      // foreground 복귀 시 재입장 처리 → isPresent=true
      _updateReadCursorInBackground(isEntered: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _openChatRoomRegistry.unregister(owner: this);
    _stopRoomMessageSubscription();
    _stopMessageUpdateSubscription();
    _reconnectSubscription?.cancel();
    // 읽음·추천: 이 화면이 구독한 경우만 해제 (같은 방 다른 화면 참조 카운트 보호)
    if (_readEventSubscription != null) {
      _readEventSubscription?.cancel();
      _wsService.unsubscribeFromReadEvents(widget.chatRoomId);
    }
    if (_recommendationSubscription != null) {
      _recommendationSubscription?.cancel();
      _wsService.unsubscribeFromRecommendations(widget.chatRoomId);
    }
    _pollerSubscription?.cancel();
    _wsImageFetchTimer?.cancel();
    for (final timer in _sendEchoTimeoutTimers.values) {
      timer.cancel();
    }
    _stopInputConvenience();
    _messageController.dispose();
    _scrollController.removeListener(_onMessageListScrolled);
    _scrollController.removeListener(_onScrollPositionChangedForLatestButton);
    _scrollController.dispose();
    ChatMemberStatusPoller.instance.stop(owner: this);
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
        onBackPressed: () => Navigator.of(context).pop(),
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
          appBar: _buildCachedAppBar(),
          body: Column(
            children: [
              _buildCachedTradeInfoCard(),
              ChatConnectionBanner(connectionStatus: _wsService.connectionStatus),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildMessageList()),
                    _buildScrollToLatestButton(),
                  ],
                ),
              ),
              ChatRecommendationBanner(
                action: _resolveVisibleRecommendedAction(currentRecommendation),
                onActionPressed: _onRecommendedActionPressed,
                onDismissed: _onRecommendationDismissed,
              ),
              ChatQuickReplyBar(isVisible: _shouldShowQuickReplies, onPhraseSelected: _onQuickReplySelected),
              ChatInputBar(
                controller: _messageController,
                focusNode: _messageFocusNode,
                isInputDisabled: _isInputDisabled,
                isSendingMessage: _isSendingMessage,
                hasText: _hasText,
                inputFieldHeight: _inputFieldHeight,
                hintText: _inputHintText,
                onSend: _sendMessage,
                onPickImage: _onPickImage,
                onTakePhoto: _onTakePhoto,
                onSendLocation: _onSendLocation,
                onRequestExchange: _onRequestExchange,
                onProposeAppointment: _onProposeAppointment,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 메시지 목록 (날짜·안 읽음 구분선, 전송 상태, 교환 요청 버튼)
  Widget _buildMessageList() {
    return ChatRoomMessageList(
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
      firstUnreadMessageId: _firstUnreadMessageId,
      unreadDividerKey: _unreadDividerKey,
      onDeleteMessage: _onDeleteMessage,
      onReportMessage: _onReportMessage,
      onAcceptAppointment: _onAcceptAppointment,
      onCancelAppointment: _onCancelAppointment,
      pendingMessageActionIds: _pendingMessageActionIds,
    );
  }
}
