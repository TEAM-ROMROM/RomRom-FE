import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/chat_image_bubble.dart';

/// 채팅 메시지 아이템 위젯
/// system / text / image (업로드 중 포함) 모든 메시지 타입을 처리
class ChatMessageItem extends StatelessWidget {
  final ChatMessage message;
  final String? myMemberId;
  final double topGap;
  final bool showTime;
  final bool isUploading;
  final String opponentNickname;
  final bool showReadReceipt;

  const ChatMessageItem({
    super.key,
    required this.message,
    required this.myMemberId,
    required this.topGap,
    required this.showTime,
    required this.isUploading,
    required this.opponentNickname,
    this.showReadReceipt = false,
  });

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.system) {
      return _buildSystemMessage();
    }
    return _buildRegularMessage(context);
  }

  Widget _buildSystemMessage() {
    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Align(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(100.r), color: AppColors.secondaryBlack1),
          child: Text(
            '$opponentNickname님이 채팅방을 나갔습니다.',
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
            if (showReadReceipt) ...[_buildReadReceiptText(), SizedBox(width: 4.w)],
            if (showTime) ...[_buildTimeText(), SizedBox(width: 8.w)],
            _buildBubble(context, isMine: true),
          ],
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context, {required bool isMine}) {
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
      style: CustomTextStyles.p3.copyWith(fontSize: 11.sp, color: AppColors.primaryYellow, fontWeight: FontWeight.w400),
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
                child: const Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(color: AppColors.primaryYellow),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
