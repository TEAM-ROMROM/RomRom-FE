import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/member_report_screen.dart';
import 'package:romrom_fe/screens/profile/profile_screen.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/romrom_context_menu.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';

/// 채팅방 앱바
/// [onBlockConfirm] 차단 확인 시 호출 - API 호출 및 채팅방 나가기 처리
/// [onLeaveChatRoomConfirm] 채팅방 나가기 확인 시 호출 - API 호출 및 화면 이동 처리
CommonAppBar buildChatRoomAppBar({
  required BuildContext context,
  required String opponentNickname,
  required String? opponentId,
  required bool isOpponentOnline,
  required DateTime? opponentLastActiveAt,
  required VoidCallback onBackPressed,
  required Future<void> Function() onBlockConfirm,
  required Future<void> Function() onLeaveChatRoomConfirm,
}) {
  return CommonAppBar(
    title: opponentNickname,
    onTitleTap: () {
      if (opponentId != null) {
        context.navigateTo(screen: ProfileScreen(memberId: opponentId));
      }
    },
    onBackPressed: onBackPressed,
    showBottomBorder: true,
    titleWidgets: _buildTitleWidgets(
      opponentNickname: opponentNickname,
      isOpponentOnline: isOpponentOnline,
      opponentLastActiveAt: opponentLastActiveAt,
    ),
    actions: [
      _buildContextMenu(
        context: context,
        opponentId: opponentId,
        onBlockConfirm: onBlockConfirm,
        onLeaveChatRoomConfirm: onLeaveChatRoomConfirm,
      ),
    ],
  );
}

Widget _buildTitleWidgets({
  required String opponentNickname,
  required bool isOpponentOnline,
  required DateTime? opponentLastActiveAt,
}) {
  return Padding(
    padding: EdgeInsets.only(top: 6.0.h),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 240.w,
          child: Text(
            opponentNickname,
            textAlign: TextAlign.center,
            style: CustomTextStyles.h3.copyWith(fontWeight: FontWeight.w600, overflow: TextOverflow.ellipsis),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 9.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOpponentOnline ? AppColors.chatActiveStatus : AppColors.chatInactiveStatus,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                isOpponentOnline ? '활동 중' : getLastActivityTime(opponentLastActiveAt),
                style: CustomTextStyles.p2.copyWith(color: AppColors.opacity50White),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildContextMenu({
  required BuildContext context,
  required String? opponentId,
  required Future<void> Function() onBlockConfirm,
  required Future<void> Function() onLeaveChatRoomConfirm,
}) {
  return Padding(
    padding: EdgeInsets.only(right: 16.0.w, bottom: 8.h),
    child: RomRomContextMenu(
      items: [
        ContextMenuItem(
          id: 'report',
          icon: AppIcons.report,
          title: '신고하기',
          onTap: () {
            if (opponentId != null) {
              context.navigateTo(screen: MemberReportScreen(memberId: opponentId));
            }
          },
          showDividerAfter: true,
        ),
        ContextMenuItem(
          id: 'block',
          icon: AppIcons.slashCircle,
          iconColor: AppColors.itemOptionsMenuRedIcon,
          title: '차단하기',
          textColor: AppColors.itemOptionsMenuRedText,
          onTap: () async {
            await CommonModal.confirm(
              context: context,
              message: '상대방을 차단하시겠습니까?\n차단한 사용자는 설정에서 확인할 수 있습니다.',
              cancelText: '취소',
              confirmText: '차단',
              onCancel: () => Navigator.of(context).pop(),
              onConfirm: () async {
                try {
                  await onBlockConfirm();
                  if (context.mounted) Navigator.of(context).pop(true);
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    CommonSnackBar.show(
                      context: context,
                      type: SnackBarType.error,
                      message: '회원 차단 실패: ${ErrorUtils.getErrorMessage(e)}',
                    );
                  }
                }
              },
            );
          },
          showDividerAfter: true,
        ),
        ContextMenuItem(
          id: 'leave_chat_room',
          icon: AppIcons.chatOut,
          iconColor: AppColors.itemOptionsMenuRedIcon,
          title: '채팅방 나가기',
          textColor: AppColors.itemOptionsMenuRedText,
          onTap: () async {
            await CommonModal.confirm(
              context: context,
              message: '정말로 채팅방을 나가시겠습니까?',
              cancelText: '취소',
              confirmText: '나가기',
              onCancel: () => Navigator.of(context).pop(),
              onConfirm: () async {
                try {
                  await onLeaveChatRoomConfirm();
                  if (context.mounted) Navigator.of(context).pop(true);
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    CommonSnackBar.show(context: context, message: '채팅방 나가기 실패: ${ErrorUtils.getErrorMessage(e)}');
                  }
                }
              },
            );
          },
        ),
      ],
    ),
  );
}
