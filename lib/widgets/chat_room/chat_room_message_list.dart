// 채팅방 메시지 목록: 빈 목록 안내 / 최신이 아래인 reverse 목록 (날짜·안 읽음 구분선·간격·시각·읽음·전송 상태·교환 요청 버튼 판정, 맨 위 이전 메시지 로딩)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/chat_room_message_rules.dart';
import 'package:romrom_fe/widgets/chat_message_item.dart';
import 'package:romrom_fe/widgets/chat_room/chat_date_divider.dart';
import 'package:romrom_fe/widgets/chat_room/chat_unread_divider.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';

class ChatRoomMessageList extends StatelessWidget {
  // reverse 정렬 (index 0 = 최신)
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final String? myMemberId;
  final String opponentNickname;
  // 업로드 중 이미지 버블 메시지 ID
  final Set<String> uploadingMessageIds;
  // 서버 응답 대기 중인 내 로컬 메시지 ID / 그중 전송 실패 ID
  final Set<String> pendingLocalMessageIds;
  final Set<String> failedLocalMessageIds;
  // 이전 메시지 조회 중 (목록 맨 위 로딩 표시) / 조회 실패 (맨 위 다시 불러오기 행)
  final bool isLoadingOlderMessages;
  final bool hasOlderMessagesLoadFailed;
  final VoidCallback onRetryOlderMessages;
  // 상대방이 읽은 최신 내 메시지 ID (읽음 표시 위치)
  final String? lastReadMyMessageId;
  final bool isTradeCompleted;
  // 교환 요청 취소·거절·완료 API 진행 중 (버튼 비활성)
  final bool isTradeActionPending;
  // 활성 교환 요청 버튼: 내 요청 > 취소, 상대 요청 > 거절·완료
  final VoidCallback onCancelTradeRequest;
  final VoidCallback onRejectTradeRequest;
  final VoidCallback onConfirmTradeRequest;
  // 실패 메시지 다시 보내기·삭제 (로컬 메시지 ID)
  final void Function(String localMessageId) onRetryFailedMessage;
  final void Function(String localMessageId) onDeleteFailedMessage;
  // 완료 카드 '후기 쓰기' (작성 불가면 null)
  final VoidCallback? onWriteReview;
  // 진입 시 안 읽은 첫 메시지 ID ('여기까지 읽었어요' 구분선 위치, null > 숨김) / 구분선 위치 이동용 키
  final String? firstUnreadMessageId;
  final Key? unreadDividerKey;

  const ChatRoomMessageList({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.myMemberId,
    required this.opponentNickname,
    required this.uploadingMessageIds,
    required this.pendingLocalMessageIds,
    required this.failedLocalMessageIds,
    required this.isLoadingOlderMessages,
    required this.hasOlderMessagesLoadFailed,
    required this.onRetryOlderMessages,
    required this.lastReadMyMessageId,
    required this.isTradeCompleted,
    required this.isTradeActionPending,
    required this.onCancelTradeRequest,
    required this.onRejectTradeRequest,
    required this.onConfirmTradeRequest,
    required this.onRetryFailedMessage,
    required this.onDeleteFailedMessage,
    required this.onWriteReview,
    this.firstUnreadMessageId,
    this.unreadDividerKey,
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
      // reverse 목록 마지막 index = 화면 맨 위 > 이전 메시지 로딩·다시 불러오기 자리
      itemCount: messages.length + (isLoadingOlderMessages || hasOlderMessagesLoadFailed ? 1 : 0),
      itemBuilder: (context, index) =>
          index == messages.length ? _buildOlderMessagesStatusRow() : _buildMessageItem(context, index),
    );
  }

  /// 목록 맨 위 행: 조회 중 > 로딩, 실패 > 다시 불러오기
  Widget _buildOlderMessagesStatusRow() {
    if (isLoadingOlderMessages) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CommonLoadingIndicator()),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onRetryOlderMessages,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            '이전 메시지를 불러오지 못했어요 · 다시 불러오기',
            style: CustomTextStyles.p3.copyWith(color: AppColors.opacity60White, decoration: TextDecoration.underline),
          ),
        ),
      ),
    );
  }

  /// 메시지 1건: 날짜·안 읽음 구분선 > 간격(구분선 아래 16.h, 같은 발신자·종류 8.h, 그 외 24.h) > 시각 표시 > 교환 요청 버튼 콜백 > 전송 상태 > 메시지 아이템
  Widget _buildMessageItem(BuildContext context, int index) {
    final message = messages[index];
    final bool showDateDivider = shouldShowDateDivider(messages: messages, index: index);
    final bool shouldShowUnreadDivider = message.chatMessageId != null && message.chatMessageId == firstUnreadMessageId;
    final double topGap = (showDateDivider || shouldShowUnreadDivider)
        ? 16.h
        : isGroupedWithOlderMessage(messages: messages, index: index)
        ? 8.h
        : 24.h;
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

    final String? messageId = message.chatMessageId;
    final messageItem = ChatMessageItem(
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
      onWriteReview: message.type == MessageType.tradeCompleted ? onWriteReview : null,
      isTradeActionPending: isTradeActionPending,
      sendStatus: resolveMessageSendStatus(
        messageId: messageId,
        pendingLocalMessageIds: pendingLocalMessageIds,
        failedLocalMessageIds: failedLocalMessageIds,
      ),
      onRetrySend: messageId == null ? null : () => onRetryFailedMessage(messageId),
      onDeleteFailedMessage: messageId == null ? null : () => onDeleteFailedMessage(messageId),
    );
    if (!showDateDivider && !shouldShowUnreadDivider) return messageItem;

    // reverse 목록이라 Column 위쪽 = 더 오래된 쪽 (안 읽음 구분선 > 날짜 구분선 > 안 읽은 첫 메시지)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (shouldShowUnreadDivider) ChatUnreadDivider(key: unreadDividerKey),
        if (showDateDivider) ChatDateDivider(date: message.createdDate!),
        messageItem,
      ],
    );
  }
}
