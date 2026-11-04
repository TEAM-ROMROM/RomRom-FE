// 채팅 메시지 길게 누르기 시트 (사진·위치 말풍선용, 글 말풍선은 선택 툴바에 같은 항목 추가): 삭제·신고 (#1006)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/chat_message_action.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 메시지 동작 시트: 가능한 동작만 표시 > 고른 동작 반환 (바깥 탭·뒤로 > null)
Future<ChatMessageAction?> showChatMessageActionSheet({
  required BuildContext context,
  required List<ChatMessageAction> actions,
}) {
  if (actions.isEmpty) return Future<ChatMessageAction?>.value();
  return showModalBottomSheet<ChatMessageAction>(
    context: context,
    backgroundColor: AppColors.transparent,
    builder: (sheetContext) => _ChatMessageActionSheet(actions: actions),
  );
}

class _ChatMessageActionSheet extends StatelessWidget {
  final List<ChatMessageAction> actions;

  const _ChatMessageActionSheet({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(color: AppColors.secondaryBlack2, borderRadius: BorderRadius.circular(2.r)),
            ),
          ),
          const SizedBox(height: 16),
          for (final action in actions) _buildActionRow(context, action),
          const SizedBox(height: 8),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, ChatMessageAction action) {
    final Color contentColor = action.isDestructive ? AppColors.itemOptionsMenuRedText : AppColors.textColorWhite;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context, action),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Row(
            children: [
              Icon(
                action == ChatMessageAction.delete ? AppIcons.trash : AppIcons.report,
                size: 20,
                color: action.isDestructive ? AppColors.itemOptionsMenuRedIcon : AppColors.opacity60White,
              ),
              const SizedBox(width: 12),
              Text(
                action.label,
                style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500, color: contentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
