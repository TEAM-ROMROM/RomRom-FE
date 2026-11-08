import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:romrom_fe/enums/chat_message_action.dart';
import 'package:romrom_fe/enums/chat_message_send_status.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/chat_message_action_rules.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/chat_image_bubble.dart';
import 'package:romrom_fe/widgets/chat_location_bubble.dart';
import 'package:romrom_fe/widgets/chat_room/chat_appointment_card.dart';
import 'package:romrom_fe/widgets/chat_room/chat_message_action_sheet.dart';
import 'package:romrom_fe/widgets/chat_room/chat_message_send_status_view.dart';
import 'package:romrom_fe/widgets/chat_room/chat_trade_system_message.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';

/// 채팅 메시지 아이템 위젯
/// system / text / image (업로드 중 포함) / 위치 / 거래 완료 시스템 메시지 / 약속 카드 / 삭제된 메시지 처리, 내 메시지 전송 상태 표시
/// 길게 누르기: 글 > 선택 툴바(복사) + 삭제·신고, 사진·위치 > 동작 시트
class ChatMessageItem extends StatelessWidget {
  final ChatMessage message;
  final String? myMemberId;
  final double topGap;
  final bool showTime;
  final bool isUploading;
  final String opponentNickname;
  final bool showReadReceipt;

  /// 거래 완료 요청 취소 콜백 (내가 보낸 요청이 활성 상태일 때만 non-null)
  final VoidCallback? onCancelTradeRequest;

  /// 거래 완료 요청 거절 콜백 (상대방이 보낸 요청이 활성 상태일 때만 non-null)
  final VoidCallback? onRejectTradeRequest;

  /// 거래 완료 요청 확인 콜백 (상대방이 보낸 요청이 활성 상태일 때만 non-null)
  final VoidCallback? onConfirmTradeRequest;

  /// 완료 카드 '후기 쓰기' 콜백 (후기 작성 가능할 때만 non-null)
  final VoidCallback? onWriteReview;

  // 거래 요청 취소·거절·완료 API 진행 중 여부 (true면 버튼 비활성 표시·탭 무시)
  final bool isTradeActionPending;

  // 내 메시지 전송 상태 (전송 중·실패면 시각·읽음 대신 상태 표시)
  final ChatMessageSendStatus sendStatus;

  /// 실패 메시지 다시 보내기·삭제 콜백
  final VoidCallback? onRetrySend;
  final VoidCallback? onDeleteFailedMessage;

  /// 내 메시지 삭제·상대 메시지 신고 콜백 (가능할 때만 non-null > 길게 누르기 메뉴 항목)
  final VoidCallback? onDeleteMessage;
  final VoidCallback? onReportMessage;

  /// 약속 수락·취소 콜백 (버튼 노출 조건일 때만 non-null) / 진행 중 여부
  final VoidCallback? onAcceptAppointment;
  final VoidCallback? onCancelAppointment;
  final bool isAppointmentActionPending;

  const ChatMessageItem({
    super.key,
    required this.message,
    required this.myMemberId,
    required this.topGap,
    required this.showTime,
    required this.isUploading,
    required this.opponentNickname,
    this.showReadReceipt = false,
    this.onCancelTradeRequest,
    this.onRejectTradeRequest,
    this.onConfirmTradeRequest,
    this.onWriteReview,
    this.isTradeActionPending = false,
    this.sendStatus = ChatMessageSendStatus.sent,
    this.onRetrySend,
    this.onDeleteFailedMessage,
    this.onDeleteMessage,
    this.onReportMessage,
    this.onAcceptAppointment,
    this.onCancelAppointment,
    this.isAppointmentActionPending = false,
  });

  // 길게 누르기 메뉴에 보일 동작 (삭제·신고 중 가능한 것만)
  List<ChatMessageAction> get _availableActions => [
    if (onDeleteMessage != null) ChatMessageAction.delete,
    if (onReportMessage != null) ChatMessageAction.report,
  ];

  @override
  Widget build(BuildContext context) {
    final type = message.type;
    if (type == MessageType.system) {
      return _buildSimplePill('$opponentNickname님이 채팅방을 나갔습니다.');
    }
    if (ChatTradeSystemMessage.isTradeSystemMessageType(type)) {
      return ChatTradeSystemMessage(
        message: message,
        myMemberId: myMemberId,
        topGap: topGap,
        opponentNickname: opponentNickname,
        onCancelTradeRequest: onCancelTradeRequest,
        onRejectTradeRequest: onRejectTradeRequest,
        onConfirmTradeRequest: onConfirmTradeRequest,
        onWriteReview: onWriteReview,
        isTradeActionPending: isTradeActionPending,
      );
    }
    final appointment = message.appointment;
    if (appointment != null && message.isDeleted != true) {
      return ChatAppointmentCard(
        appointment: appointment,
        isMine: message.senderId == myMemberId,
        opponentNickname: opponentNickname,
        topGap: topGap,
        onAccept: onAcceptAppointment,
        onCancel: onCancelAppointment,
        isActionPending: isAppointmentActionPending,
      );
    }
    return _buildRegularMessage(context);
  }

  /// 고른 동작 실행 (삭제·신고)
  void _runAction(ChatMessageAction? action) {
    switch (action) {
      case ChatMessageAction.delete:
        onDeleteMessage?.call();
      case ChatMessageAction.report:
        onReportMessage?.call();
      case null:
        return;
    }
  }

  /// 사진·위치 말풍선 길게 누르기 > 동작 시트
  Future<void> _showActionSheet(BuildContext context) async {
    final action = await showChatMessageActionSheet(context: context, actions: _availableActions);
    _runAction(action);
  }

  /// 삭제된 메시지 말풍선 (흐린 글자, 길게 누르기 메뉴 없음)
  Widget _buildDeletedBubble() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      constraints: BoxConstraints(maxWidth: 264.w),
      decoration: BoxDecoration(
        color: AppColors.transparent,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.opacity20White),
      ),
      child: Text(
        deletedChatMessagePlaceholder,
        style: CustomTextStyles.p2.copyWith(color: AppColors.opacity50White, fontWeight: FontWeight.w400, height: 1.2),
      ),
    );
  }

  // 심플 캡슐형 시스템 메시지 (채팅방 나감 등)
  Widget _buildSimplePill(String text) {
    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Align(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(100.r), color: AppColors.secondaryBlack1),
          child: Text(
            text,
            style: CustomTextStyles.p2.copyWith(
              color: AppColors.opacity60White,
              fontWeight: FontWeight.w400,
              wordSpacing: -0.32.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildRegularMessage(BuildContext context) {
    final isMine = message.senderId == myMemberId;
    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            _buildBubble(context, isMine: false),
            if (showTime) ...[SizedBox(width: 8.w), _buildTimeText()],
          ] else ...[
            // 전송 완료 > 읽음·시각, 전송 중·실패 > 상태 표시
            if (sendStatus == ChatMessageSendStatus.sent)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showReadReceipt) ...[_buildReadReceiptText(), SizedBox(height: 4.h)],
                  if (showTime) ...[_buildTimeText()],
                ],
              )
            else
              ChatMessageSendStatusView(sendStatus: sendStatus, onRetry: onRetrySend, onDelete: onDeleteFailedMessage),
            SizedBox(width: 8.w),
            _buildBubble(context, isMine: true),
          ],
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context, {required bool isMine}) {
    if (message.isDeleted == true) return _buildDeletedBubble();
    if (message.type == MessageType.location) {
      return _wrapWithActionSheet(context, ChatLocationBubble(message: message));
    }
    if (message.type == MessageType.image) {
      return isUploading
          ? _buildUploadingBubble(context)
          : _wrapWithActionSheet(context, chatImageBubble(context, message));
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      constraints: BoxConstraints(maxWidth: 264.w),
      decoration: BoxDecoration(
        color: isMine ? AppColors.primaryYellow : AppColors.secondaryBlack1,
        borderRadius: BorderRadius.circular(10.r),
      ),
      // SelectableLinkify: 길게 눌러 부분 선택 복사 + 메시지 내 URL 자동 링크화/탭 열기
      child: SelectableLinkify(
        text: message.content ?? '',
        options: const LinkifyOptions(humanize: false),
        style: CustomTextStyles.p2.copyWith(
          color: isMine ? AppColors.textColorBlack : AppColors.textColorWhite,
          fontWeight: FontWeight.w400,
          height: 1.2,
        ),
        // 링크 전용 색이 디자인 시스템에 없어 본문 글자색 유지 + 밑줄로만 구분
        linkStyle: CustomTextStyles.p2.copyWith(
          color: isMine ? AppColors.textColorBlack : AppColors.textColorWhite,
          fontWeight: FontWeight.w400,
          height: 1.2,
          decoration: TextDecoration.underline,
        ),
        onOpen: (link) => _openUrl(context, link.url),
        // flutter_linkify 기본값 null이면 길게 눌러도 메뉴 없음 > 플랫폼 기본 선택 메뉴(복사·전체 선택)
        // 기본 항목(복사·전체 선택) 뒤에 삭제·신고 추가
        contextMenuBuilder: (context, editableTextState) => AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: [
            ...editableTextState.contextMenuButtonItems,
            for (final action in _availableActions)
              ContextMenuButtonItem(
                label: action.label,
                onPressed: () {
                  editableTextState.hideToolbar();
                  _runAction(action);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 길게 누르기 동작이 있으면 시트 연결 (없으면 그대로)
  Widget _wrapWithActionSheet(BuildContext context, Widget bubble) {
    if (_availableActions.isEmpty) return bubble;
    return GestureDetector(onLongPress: () => _showActionSheet(context), child: bubble);
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        CommonSnackBar.show(context: context, message: '링크를 열 수 없습니다.', type: SnackBarType.error);
      }
    } catch (_) {
      if (context.mounted) {
        CommonSnackBar.show(context: context, message: '링크를 열 수 없습니다.', type: SnackBarType.error);
      }
    }
  }

  Widget _buildTimeText() {
    return Text(
      formatMessageTime(message.createdDate),
      style: CustomTextStyles.p3.copyWith(
        fontSize: 12.sp,
        color: AppColors.opacity50White,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildReadReceiptText() {
    return Text(
      '읽음',
      style: CustomTextStyles.p3.copyWith(color: AppColors.opacity50White, fontWeight: FontWeight.w400, height: 1.2),
    );
  }

  /// 업로드 중 사진 말풍선: 압축 전 로컬 사진을 셀 표시 크기로 디코딩 (원본 디코딩 시 장당 수십 MB) + 스피너
  Widget _buildUploadingBubble(BuildContext context) {
    final paths = message.imageUrls ?? [];
    if (paths.isEmpty) return const SizedBox.shrink();

    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    Widget localCell(int index) {
      final path = paths[index];
      if (path.isEmpty) return const ColoredBox(color: AppColors.opacity10White);
      final decodeSize = photoGridCellDecodeSize(
        photoCount: paths.length,
        index: index,
        width: 264.w,
        devicePixelRatio: devicePixelRatio,
      );
      return Image.file(File(path), fit: BoxFit.cover, cacheWidth: decodeSize.width, cacheHeight: decodeSize.height);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: SizedBox(
        width: 264.w,
        child: Stack(
          children: [
            buildPhotoGrid(photoCount: paths.length, cellBuilder: localCell, width: 264.w),
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.primaryBlack.withValues(alpha: 0.5),
                // 이미지 업로드 중 오버레이 스피너
                child: const Center(child: CommonLoadingIndicator(size: 32.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
