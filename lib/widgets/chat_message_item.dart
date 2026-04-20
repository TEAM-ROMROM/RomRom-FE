import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/chat_image_bubble.dart';
import 'package:romrom_fe/widgets/chat_location_bubble.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';

/// 채팅 메시지 아이템 위젯
/// system / text / image (업로드 중 포함) / 거래 완료 시스템 메시지 모든 타입 처리
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
  });

  @override
  Widget build(BuildContext context) {
    final type = message.type;
    if (type == MessageType.system) {
      return _buildSimplePill('$opponentNickname님이 채팅방을 나갔습니다.');
    }
    if (type == MessageType.tradeCompleteRequest ||
        type == MessageType.tradeCompleteRequestCanceled ||
        type == MessageType.tradeCompleteRequestRejected ||
        type == MessageType.tradeCompleted) {
      return _buildTradeSystemMessage();
    }
    return _buildRegularMessage(context);
  }

  // ── 거래 완료 시스템 메시지 ──────────────────────────────────────────────

  Widget _buildTradeSystemMessage() {
    final type = message.type;

    if (type == MessageType.tradeCompleteRequestCanceled) {
      return _buildSimpleCard('교환 완료 요청이 취소되었습니다.', '요청이 정상적으로 취소되었습니다.');
    }
    if (type == MessageType.tradeCompleteRequestRejected) {
      return _buildSimpleCard('⛔️ 교환 완료 요청이 거절되었습니다.', '실수로 거절하셨다면, 다시 교환 완료를 요청해주세요');
    }
    if (type == MessageType.tradeCompleted) {
      return _buildSimpleCard('교환이 완료되었습니다!', '거래 횟수가 1회 올라갔어요! 서로에게 남긴 후기는 프로필에서 확인할 수 있습니다.');
    }

    // TRADE_COMPLETE_REQUEST
    final isMine = message.senderId == myMemberId;
    final hasButtons = isMine ? onCancelTradeRequest != null : onRejectTradeRequest != null;

    if (hasButtons) {
      return _buildTradeRequestCard(isMine: isMine);
    }

    // 비활성(이미 처리된) 요청 - 심플 텍스트
    final inactiveText = isMine ? '교환 완료를 요청했습니다.' : '$opponentNickname님이 교환 완료를 요청했습니다.';
    return _buildSimpleCard(inactiveText, '이미 처리된 요청입니다.');
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

  // 교환 완료 요청 카드 (활성 상태)
  Widget _buildSimpleCard(String text, String subText) {
    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.exchangeRequestSystemMessageBackground,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: AppColors.exchangeRequestSystemMessageBorder,
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: CustomTextStyles.p3.copyWith(fontSize: 13.sp, color: AppColors.primaryYellow),
            ),
            SizedBox(height: 8.h),
            Text(
              subText,
              style: CustomTextStyles.p3.copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.primaryYellow,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 교환 완료 요청
  Widget _buildTradeRequestCard({required bool isMine}) {
    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Container(
        padding: EdgeInsets.fromLTRB(8.w, 12.h, 8.w, 8.h),
        decoration: BoxDecoration(
          color: AppColors.exchangeRequestSystemMessageBackground,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: AppColors.exchangeRequestSystemMessageBorder,
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMine ? '$opponentNickname님에게 교환 완료를 요청했습니다.' : '$opponentNickname님이 교환 완료를 요청했습니다.',
              style: CustomTextStyles.p3.copyWith(fontSize: 13.sp, color: AppColors.primaryYellow),
            ),
            SizedBox(height: 8.h),
            Text(
              isMine ? '상대방이 수락하면 미리 작성한 후기가 전달됩니다.' : '교환한 물건이 맞는지 확인해주세요. 확인 버튼을 누르면 거래가 최종 성사 됩니다.',
              style: CustomTextStyles.p3.copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.primaryYellow,
                height: 1.2,
              ),
            ),
            if (isMine)
              _tradeButton('요청 취소하기', AppColors.primaryYellow, AppColors.textColorBlack, onCancelTradeRequest)
            else
              Row(
                children: [
                  Expanded(
                    child: _tradeButton(
                      '거절하기',
                      AppColors.opacity40White,
                      AppColors.textColorBlack,
                      onRejectTradeRequest,
                    ),
                  ),
                  SizedBox(width: 7.w),
                  Expanded(
                    child: _tradeButton(
                      '확인 및 완료하기',
                      AppColors.primaryYellow,
                      AppColors.textColorBlack,
                      onConfirmTradeRequest,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _tradeButton(String label, Color bg, Color fg, VoidCallback? onTap) {
    return Container(
      height: 44.h,
      padding: EdgeInsets.only(top: 12.h),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(4.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4.r),
          highlightColor: darkenBlend(bg),
          splashColor: darkenBlend(bg).withValues(alpha: 0.3),
          child: Center(
            child: Text(label, style: CustomTextStyles.p3.copyWith(color: fg)),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (showReadReceipt) ...[_buildReadReceiptText(), SizedBox(height: 4.h)],
                if (showTime) ...[_buildTimeText()],
              ],
            ),
            SizedBox(width: 8.w),
            _buildBubble(context, isMine: true),
          ],
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context, {required bool isMine}) {
    if (message.type == MessageType.location) {
      return ChatLocationBubble(message: message);
    }
    if (message.type == MessageType.image) {
      return isUploading ? _buildUploadingBubble() : chatImageBubble(context, message);
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      constraints: BoxConstraints(maxWidth: 264.w, maxHeight: isMine ? 264.h : double.infinity),
      decoration: BoxDecoration(
        color: isMine ? AppColors.primaryYellow : AppColors.secondaryBlack1,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        message.content ?? '',
        style: CustomTextStyles.p2.copyWith(
          color: isMine ? AppColors.textColorBlack : AppColors.textColorWhite,
          fontWeight: FontWeight.w400,
          height: 1.2,
        ),
      ),
    );
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

  Widget _buildUploadingBubble() {
    final paths = message.imageUrls ?? [];
    if (paths.isEmpty) return const SizedBox.shrink();

    Widget localCell(int index) {
      final path = paths[index];
      return path.isNotEmpty
          ? Image.file(File(path), fit: BoxFit.cover)
          : const ColoredBox(color: AppColors.opacity10White);
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
