import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/apis/objects/chat_room.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/services/apis/chat_api.dart';
import 'package:romrom_fe/services/chat_websocket_service.dart';
import 'package:romrom_fe/services/member_manager_service.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatRoomScreen({
    super.key,
    required this.chatRoom,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatWebSocketService _wsService = ChatWebSocketService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  StreamSubscription<ChatMessage>? _messageSubscription;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String? _myMemberId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // 1. 현재 사용자 ID 가져오기
      _myMemberId = await MemberManager.getCurrentMemberId();

      if (_myMemberId == null) {
        throw Exception('사용자 정보를 불러올 수 없습니다');
      }

      // 2. WebSocket 연결
      await _wsService.connect();

      // 3. 과거 메시지 조회 (REST API)
      final chatApi = ChatApi();
      final response = await chatApi.getChatMessages(
        chatRoomId: widget.chatRoom.chatRoomId!,
        pageNumber: 0,
        pageSize: 50,
      );

      if (!mounted) return;

      setState(() {
        _messages = response.messages?.content ?? [];
      });

      // 4. 실시간 메시지 구독 (WebSocket)
      _messageSubscription = _wsService
          .subscribeToChatRoom(widget.chatRoom.chatRoomId!)
          .listen((newMessage) {
        if (!mounted) return;

        setState(() {
          // 중복 메시지 방지 (messageId 기준)
          final isDuplicate = _messages.any(
            (msg) => msg.chatMessageId == newMessage.chatMessageId,
          );

          if (!isDuplicate) {
            _messages.insert(0, newMessage);
          }
        });

        _scrollToBottom();
      });

      setState(() => _isLoading = false);
      _scrollToBottom();
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

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      _wsService.sendMessage(
        chatRoomId: widget.chatRoom.chatRoomId!,
        content: content,
        type: MessageType.text,
      );

      _messageController.clear();
    } catch (e) {
      debugPrint('메시지 전송 실패: $e');
      CommonSnackBar.show(
        context: context,
        message: '메시지 전송에 실패했습니다',
        type: SnackBarType.error,
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  String _formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('a h:mm', 'ko_KR').format(dateTime);
  }

  String _getLastActivityTime() {
    final lastActivity = widget.chatRoom.getLastActivityTime();
    final now = DateTime.now();
    final difference = now.difference(lastActivity);

    if (difference.inMinutes < 1) {
      return '방금 전 활동';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전 활동';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전 활동';
    } else {
      return '${difference.inDays}일 전 활동';
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _wsService.unsubscribeFromChatRoom(widget.chatRoom.chatRoomId!);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primaryBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryYellow),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: AppColors.primaryBlack,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlack,
          leading: IconButton(
            icon: const Icon(
              AppIcons.navigateBefore,
              color: AppColors.textColorWhite,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage,
                style: CustomTextStyles.p1.copyWith(
                  color: AppColors.textColorWhite,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitialData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                ),
                child: Text(
                  '다시 시도',
                  style: CustomTextStyles.p2.copyWith(
                    color: AppColors.primaryBlack,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTradeInfoCard(),
          Expanded(
            child: _buildMessageList(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryBlack,
      leading: IconButton(
        icon: Icon(
          AppIcons.navigateBefore,
          color: AppColors.textColorWhite,
          size: 24.sp,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        children: [
          Text(
            widget.chatRoom.getOpponentNickname(_myMemberId!),
            style: CustomTextStyles.p1,
          ),
          const SizedBox(height: 2),
          Text(
            _getLastActivityTime(),
            style: CustomTextStyles.p3.copyWith(
              color: AppColors.opacity50White,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.more_vert,
            color: AppColors.textColorWhite,
          ),
          onPressed: () {
            // TODO: 채팅방 메뉴 (나가기, 신고 등)
          },
        ),
      ],
    );
  }

  Widget _buildTradeInfoCard() {
    final item = widget.chatRoom.tradeRequestHistory?.takeItem;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: const BoxDecoration(
        color: AppColors.opacity10White,
        border: Border(
          bottom: BorderSide(
            color: AppColors.opacity20White,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: Image.network(
              item?.itemImages?.first.imageUrl ?? '',
              width: 73.w,
              height: 73.h,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ErrorImagePlaceholder(
                size: Size(73.w, 73.h),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item?.itemName ?? '제목 없음',
                  style: CustomTextStyles.p2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatPrice(item?.price ?? 0)}원',
                  style: CustomTextStyles.p2.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (item?.itemImages != null && item!.itemImages!.length > 1)
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: Image.network(
                item.itemImages![1].imageUrl ?? '',
                width: 52.w,
                height: 52.h,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          '메시지를 입력해보세요',
          style: CustomTextStyles.p2.copyWith(
            color: AppColors.opacity50White,
          ),
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMine = message.senderId == _myMemberId;

        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            constraints: BoxConstraints(maxWidth: 280.w),
            decoration: BoxDecoration(
              color: isMine
                  ? AppColors.primaryYellow
                  : AppColors.opacity20White,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content ?? '',
                  style: CustomTextStyles.p2.copyWith(
                    color: isMine
                        ? AppColors.textColorBlack
                        : AppColors.textColorWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMessageTime(message.createdDate),
                  style: CustomTextStyles.p3.copyWith(
                    color: isMine
                        ? AppColors.textColorBlack.withValues(alpha: 0.6)
                        : AppColors.opacity50White,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: const BoxDecoration(
        color: AppColors.primaryBlack,
        border: Border(
          top: BorderSide(
            color: AppColors.opacity20White,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.add,
              color: AppColors.textColorWhite,
            ),
            onPressed: () {
              // TODO: 이미지 전송 기능
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: CustomTextStyles.p2,
              maxLines: null,
              decoration: InputDecoration(
                hintText: '안녕하세요',
                hintStyle: CustomTextStyles.p2.copyWith(
                  color: AppColors.opacity50White,
                ),
                filled: true,
                fillColor: AppColors.opacity10White,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 10.h,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: const BoxDecoration(
                color: AppColors.primaryYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_upward,
                color: AppColors.textColorBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
