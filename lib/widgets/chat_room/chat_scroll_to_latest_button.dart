// 채팅방 맨 아래로 버튼: 위로 올려 보는 중 노출, 상대 새 메시지 있으면 '새 메시지 N' 알약, 탭 > 맨 아래로
import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/chat_room_live_message_rules.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';

class ChatScrollToLatestButton extends StatelessWidget {
  // 맨 아래에서 멀어졌는지 (false > 숨김)
  final bool isVisible;
  // 위로 보는 중 쌓인 상대 새 메시지 수 (0 > 화살표 원형 버튼, 1 이상 > 알약)
  final int unseenMessageCount;
  final VoidCallback onPressed;

  const ChatScrollToLatestButton({
    super.key,
    required this.isVisible,
    required this.unseenMessageCount,
    required this.onPressed,
  });

  // 버튼 최소 높이·아이콘 크기 (고정 px, iPad 확대 방지)
  static const double buttonHeight = 36;
  static const double arrowIconSize = 22;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedOpacity(
        opacity: isVisible ? 1 : 0,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: Semantics(
          button: true,
          label: unseenMessageCount > 0 ? formatNewMessageCountLabel(unseenMessageCount) : '맨 아래로',
          child: AppPressable(
            onTap: onPressed,
            scaleDown: AppPressable.scaleIcon,
            enableRipple: false,
            child: Container(
              // 최소 크기만 고정 (iPad 글자 확대 시 알약 높이도 늘어남 > 잘림 방지)
              constraints: const BoxConstraints(minWidth: buttonHeight, minHeight: buttonHeight),
              padding: EdgeInsets.symmetric(horizontal: unseenMessageCount > 0 ? 14 : 0),
              decoration: BoxDecoration(
                color: unseenMessageCount > 0 ? AppColors.primaryYellow : AppColors.secondaryBlack1,
                borderRadius: BorderRadius.circular(buttonHeight / 2),
                boxShadow: const [BoxShadow(color: AppColors.opacity20Black, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: unseenMessageCount > 0 ? _buildNewMessagePill() : _buildArrow(AppColors.textColorWhite),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArrow(Color color) => Icon(Icons.keyboard_arrow_down_rounded, color: color, size: arrowIconSize);

  /// 알약: '새 메시지 N' > 아래 화살표
  Widget _buildNewMessagePill() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatNewMessageCountLabel(unseenMessageCount),
          style: CustomTextStyles.p3.copyWith(color: AppColors.primaryBlack, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 2),
        _buildArrow(AppColors.primaryBlack),
      ],
    );
  }
}
