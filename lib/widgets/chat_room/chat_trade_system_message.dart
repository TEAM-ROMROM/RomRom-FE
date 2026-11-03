// 교환 완료 시스템 메시지 카드: 요청(활성 버튼·비활성 안내), 취소, 거절, 완료(후기 쓰기)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';

// 카드 버튼 위 여백·버튼 높이 (px)
const double _tradeButtonTopGap = 12;
const double _tradeButtonHeight = 32;

class ChatTradeSystemMessage extends StatelessWidget {
  final ChatMessage message;
  final String? myMemberId;
  final double topGap;
  final String opponentNickname;

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

  const ChatTradeSystemMessage({
    super.key,
    required this.message,
    required this.myMemberId,
    required this.topGap,
    required this.opponentNickname,
    this.onCancelTradeRequest,
    this.onRejectTradeRequest,
    this.onConfirmTradeRequest,
    this.onWriteReview,
    this.isTradeActionPending = false,
  });

  /// 교환 완료 시스템 메시지 종류인지 (요청·취소·거절·완료)
  static bool isTradeSystemMessageType(MessageType? type) =>
      type == MessageType.tradeCompleteRequest ||
      type == MessageType.tradeCompleteRequestCanceled ||
      type == MessageType.tradeCompleteRequestRejected ||
      type == MessageType.tradeCompleted;

  @override
  Widget build(BuildContext context) {
    final type = message.type;

    if (type == MessageType.tradeCompleteRequestCanceled) {
      return _buildSimpleCard('교환 완료 요청이 취소되었습니다.', '요청이 정상적으로 취소되었습니다.');
    }
    if (type == MessageType.tradeCompleteRequestRejected) {
      return _buildSimpleCard('⛔️ 교환 완료 요청이 거절되었습니다.', '실수로 거절하셨다면, 다시 교환 완료를 요청해주세요');
    }
    if (type == MessageType.tradeCompleted) {
      return _buildSimpleCard(
        '교환이 완료되었습니다!',
        '거래 횟수가 1회 올라갔어요! 서로에게 남긴 후기는 프로필에서 확인할 수 있습니다.',
        actionButton: onWriteReview == null
            ? null
            : _tradeButton(
                '후기 쓰기',
                AppColors.primaryYellow,
                AppColors.opacity50PrimaryYellow,
                AppColors.textColorBlack,
                onWriteReview,
              ),
      );
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

  // 안내 카드 (제목·설명, 버튼 옵션)
  Widget _buildSimpleCard(String text, String subText, {Widget? actionButton}) {
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
            ?actionButton,
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
              isMine ? '상대방이 확인하면 교환이 완료되고, 서로 후기를 남길 수 있어요.' : '교환한 물품이 맞는지 확인해주세요. 확인 버튼을 누르면 거래가 최종 성사 됩니다.',
              style: CustomTextStyles.p3.copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.primaryYellow,
                height: 1.2,
              ),
            ),
            if (isMine)
              _tradeButton(
                '요청 취소하기',
                AppColors.primaryYellow,
                AppColors.opacity50PrimaryYellow,
                AppColors.textColorBlack,
                onCancelTradeRequest,
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _tradeButton(
                      '거절하기',
                      AppColors.opacity40White,
                      AppColors.opacity20White,
                      AppColors.textColorBlack,
                      onRejectTradeRequest,
                    ),
                  ),
                  SizedBox(width: 7.w),
                  Expanded(
                    child: _tradeButton(
                      '확인 및 완료하기',
                      AppColors.primaryYellow,
                      AppColors.opacity50PrimaryYellow,
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

  /// 거래 요청 카드 버튼 (진행 중이면 비활성 배경 + 탭 무시)
  Widget _tradeButton(String label, Color bg, Color pendingBackgroundColor, Color fg, VoidCallback? onTap) {
    // 고정 px (높이·여백을 .h로 함께 키우면 iPad에서 여백이 높이를 넘어 잘림)
    return Padding(
      padding: const EdgeInsets.only(top: _tradeButtonTopGap),
      child: SizedBox(
        height: _tradeButtonHeight,
        child: Material(
          color: isTradeActionPending ? pendingBackgroundColor : bg,
          borderRadius: BorderRadius.circular(4.r),
          child: InkWell(
            onTap: isTradeActionPending ? null : onTap,
            borderRadius: BorderRadius.circular(4.r),
            highlightColor: darkenBlend(bg),
            splashColor: darkenBlend(bg).withValues(alpha: 0.3),
            child: Center(
              child: Text(label, style: CustomTextStyles.p3.copyWith(color: fg)),
            ),
          ),
        ),
      ),
    );
  }
}
