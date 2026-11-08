import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/providers/keyword_alerts_provider.dart';
import 'package:romrom_fe/states/keyword_alerts_state.dart';
import 'package:romrom_fe/widgets/keyword_alert/keyword_alert_actions.dart';

/// 검색 결과 종 버튼: 검색어가 등록 키워드면 채운 종, 탭 > 등록·해제 토글 (#1020)
/// 등록 상태는 keywordAlertsProvider 구독, 처리 중 중복 탭 무시
class KeywordAlertBellButton extends ConsumerStatefulWidget {
  // 마지막으로 검색한 검색어
  final String keyword;

  const KeywordAlertBellButton({super.key, required this.keyword});

  @override
  ConsumerState<KeywordAlertBellButton> createState() => _KeywordAlertBellButtonState();
}

class _KeywordAlertBellButtonState extends ConsumerState<KeywordAlertBellButton> {
  bool _isToggling = false;

  /// 등록 키워드면 해제, 아니면 등록 (처리 중 탭 무시)
  Future<void> _onBellPressed() async {
    if (_isToggling) return;
    setState(() => _isToggling = true);
    try {
      final registeredKeywordAlert = (await _readLoadedKeywordAlerts())?.findByKeyword(widget.keyword);
      if (!mounted) return;
      if (registeredKeywordAlert != null) {
        await deleteKeywordAlertWithFeedback(context: context, ref: ref, keywordAlert: registeredKeywordAlert);
      } else {
        await registerKeywordAlertWithFeedback(context: context, ref: ref, keyword: widget.keyword);
      }
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  /// 불러오기 끝난 목록 (불러오는 중 > 완료 대기, 실패 > 이전 값 또는 null: 등록 검사는 서버에 맡김)
  Future<KeywordAlertsState?> _readLoadedKeywordAlerts() async {
    try {
      return await ref.read(keywordAlertsProvider.future);
    } catch (error) {
      debugPrint('[keyword alert] list not loaded before toggle : $error');
      return ref.read(keywordAlertsProvider).valueOrNull;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRegistered =
        ref.watch(keywordAlertsProvider.select((async) => async.valueOrNull?.isKeywordRegistered(widget.keyword))) ??
        false;
    return IconButton(
      onPressed: _onBellPressed,
      tooltip: isRegistered ? '키워드 알림 해제' : '키워드 알림 받기',
      icon: Icon(
        isRegistered ? Icons.notifications_rounded : Icons.notifications_none_rounded,
        size: 24,
        color: isRegistered ? AppColors.primaryYellow : AppColors.textColorWhite,
      ),
    );
  }
}
