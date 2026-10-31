import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/chat_recommended_action.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';

/// 채팅 입력창 위 AI 행동 추천 배너: 추천 문구 > 행동 버튼 > 닫기 (#759)
/// action null·NONE > 미노출 (등장·퇴장 AppMotion 전환)
class ChatRecommendationBanner extends StatelessWidget {
  // 노출할 추천 행동 (null·none > 숨김)
  final ChatRecommendedAction? action;
  final ValueChanged<ChatRecommendedAction> onActionPressed;
  final VoidCallback onDismissed;

  const ChatRecommendationBanner({
    super.key,
    required this.action,
    required this.onActionPressed,
    required this.onDismissed,
  });

  // 배너 카드 여백 (iPad 비례 확대 방지 > 고정 px)
  static const EdgeInsets _bannerMargin = EdgeInsets.fromLTRB(16, 8, 16, 0);
  static const EdgeInsets _bannerPadding = EdgeInsets.fromLTRB(14, 8, 6, 8);
  static const double _bannerCornerRadius = 12;
  static const double _iconSize = 16;
  static const double _closeIconSize = 18;

  @override
  Widget build(BuildContext context) {
    final ChatRecommendedAction? visibleAction = (action?.isRecommendation ?? false) ? action : null;
    return AnimatedSize(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      alignment: Alignment.bottomCenter,
      child: AnimatedSwitcher(
        duration: AppMotion.fast,
        switchInCurve: AppMotion.entry,
        switchOutCurve: AppMotion.accelerate,
        child: visibleAction == null
            ? const SizedBox(key: ValueKey('chat_recommendation_hidden'), width: double.infinity)
            : _buildBannerCard(visibleAction),
      ),
    );
  }

  /// 추천 카드: 아이콘 > 추천 문구 > 행동 버튼 > 닫기
  Widget _buildBannerCard(ChatRecommendedAction visibleAction) {
    return Container(
      key: ValueKey('chat_recommendation_${visibleAction.serverName}'),
      width: double.infinity,
      margin: _bannerMargin,
      padding: _bannerPadding,
      decoration: BoxDecoration(
        color: AppColors.secondaryBlack1,
        borderRadius: BorderRadius.circular(_bannerCornerRadius),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryYellow, size: _iconSize),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              visibleAction.recommendationMessage,
              style: CustomTextStyles.p3.copyWith(color: AppColors.textColorWhite, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _buildActionButton(visibleAction),
          _buildDismissButton(),
        ],
      ),
    );
  }

  /// 추천 행동 버튼 (노란 캡슐)
  Widget _buildActionButton(ChatRecommendedAction visibleAction) {
    return AppPressable(
      onTap: () => onActionPressed(visibleAction),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppColors.primaryYellow, borderRadius: BorderRadius.circular(100)),
        child: Text(visibleAction.actionLabel, style: CustomTextStyles.p3.copyWith(color: AppColors.primaryBlack)),
      ),
    );
  }

  /// 닫기 버튼 (터치 영역 확보용 여백 포함)
  Widget _buildDismissButton() {
    return Semantics(
      button: true,
      label: '추천 닫기',
      child: AppPressable(
        onTap: onDismissed,
        scaleDown: AppPressable.scaleIcon,
        enableRipple: false,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(AppIcons.cancel, color: AppColors.opacity50White, size: _closeIconSize),
        ),
      ),
    );
  }
}
