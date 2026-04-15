import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/chat_recommended_action.dart';
import 'package:romrom_fe/models/apis/objects/chat_action_recommendation_payload.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 채팅방 AI 행동 추천 배너 (입력창 바로 위)
class ChatRecommendationBanner extends StatelessWidget {
  final ChatActionRecommendationPayload recommendation;
  final VoidCallback onDismiss;
  final VoidCallback? onAction;

  const ChatRecommendationBanner({super.key, required this.recommendation, required this.onDismiss, this.onAction});

  String get _bannerText {
    switch (recommendation.action) {
      case ChatRecommendedAction.requestTradeCompletion:
        return '교환 완료를 요청해보세요';
      case ChatRecommendedAction.cancelTradeCompletionRequest:
        return '교환 요청을 취소할 수 있어요';
      case ChatRecommendedAction.rejectTradeCompletionRequest:
        return '교환 요청을 거절할 수 있어요';
      case ChatRecommendedAction.confirmTradeCompletion:
        return '교환을 완료해보세요';
      case ChatRecommendedAction.sendLocation:
        return '위치를 공유해보세요';
      case ChatRecommendedAction.none:
        return '';
    }
  }

  String get _actionLabel {
    switch (recommendation.action) {
      case ChatRecommendedAction.requestTradeCompletion:
        return '요청하기';
      case ChatRecommendedAction.cancelTradeCompletionRequest:
        return '취소하기';
      case ChatRecommendedAction.rejectTradeCompletionRequest:
        return '거절하기';
      case ChatRecommendedAction.confirmTradeCompletion:
        return '완료하기';
      case ChatRecommendedAction.sendLocation:
        return '공유하기';
      case ChatRecommendedAction.none:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.secondaryBlack1,
        border: Border(top: BorderSide(color: AppColors.opacity10White, width: 1)),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _bannerText,
              style: CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onAction != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.primaryYellow, borderRadius: BorderRadius.circular(100)),
                child: Text(
                  _actionLabel,
                  style: CustomTextStyles.p3.copyWith(color: AppColors.primaryBlack, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, color: AppColors.opacity50White, size: 18),
          ),
        ],
      ),
    );
  }
}
