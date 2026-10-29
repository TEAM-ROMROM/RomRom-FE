// 채팅방 메시지 목록: 빈 목록 안내 / 최신이 아래인 reverse 목록 (간격·시각·읽음·교환 요청 버튼 판정)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/chat_room_message_rules.dart';
import 'package:romrom_fe/widgets/chat_message_item.dart';

class ChatRoomMessageList extends StatelessWidget {
  // reverse 정렬 (index 0 = 최신)
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final String? myMemberId;
  final String opponentNickname;
  // 업로드 중 이미지 버블 메시지 ID
  final Set<String> uploadingMessageIds;
  // 상대방이 읽은 최신 내 메시지 ID (읽음 표시 위치)
  final String? lastReadMyMessageId;
  final bool isTradeCompleted;
  // 교환 요청 취소·거절·완료 API 진행 중 (버튼 비활성)
  final bool isTradeActionPending;
  // 활성 교환 요청 버튼: 내 요청 > 취소, 상대 요청 > 거절·완료
  final VoidCallback onCancelTradeRequest;
  final VoidCallback onRejectTradeRequest;
  final VoidCallback onConfirmTradeRequest;

  const ChatRoomMessageList({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.myMemberId,
    required this.opponentNickname,
    required this.uploadingMessageIds,
    required this.lastReadMyMessageId,
    required this.isTradeCompleted,
    required this.isTradeActionPending,
    required this.onCancelTradeRequest,
    required this.onRejectTradeRequest,
    required this.onConfirmTradeRequest,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Text('메시지를 입력해보세요', style: CustomTextStyles.p2.copyWith(color: AppColors.opacity50White)),
      );
    }

    return ListView.builder(
      reverse: true,
      controller: scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: messages.length,
      itemBuilder: _buildMessageItem,
    );
  }

  /// 메시지 1건: 간격(같은 발신자·종류 8.h, 그 외 24.h) > 시각 표시 > 교환 요청 버튼 콜백 > 메시지 아이템
  Widget _buildMessageItem(BuildContext context, int index) {
    final message = messages[index];
    final double topGap = isGroupedWithOlderMessage(messages: messages, index: index) ? 8.h : 24.h;
    final bool showTime = shouldShowMessageTime(messages: messages, index: index);

    // 교환 완료 요청 활성 상태면 버튼 콜백 결정
    VoidCallback? cancelTradeRequestCallback;
    VoidCallback? rejectTradeRequestCallback;
    VoidCallback? confirmTradeRequestCallback;
    if (message.type == MessageType.tradeCompleteRequest &&
        isActiveTradeRequestAt(messages: messages, index: index, isTradeCompleted: isTradeCompleted)) {
      if (message.senderId == myMemberId) {
        cancelTradeRequestCallback = onCancelTradeRequest;
      } else {
        rejectTradeRequestCallback = onRejectTradeRequest;
        confirmTradeRequestCallback = onConfirmTradeRequest;
      }
    }

    return ChatMessageItem(
      key: ValueKey(message.chatMessageId ?? '${message.senderId}_${message.createdDate?.millisecondsSinceEpoch}'),
      message: message,
      myMemberId: myMemberId,
      topGap: topGap,
      showTime: showTime,
      isUploading: uploadingMessageIds.contains(message.chatMessageId),
      opponentNickname: opponentNickname,
      showReadReceipt: message.chatMessageId != null && message.chatMessageId == lastReadMyMessageId,
      onCancelTradeRequest: cancelTradeRequestCallback,
      onRejectTradeRequest: rejectTradeRequestCallback,
      onConfirmTradeRequest: confirmTradeRequestCallback,
      isTradeActionPending: isTradeActionPending,
    );
  }
}
