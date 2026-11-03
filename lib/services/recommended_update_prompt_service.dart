import 'package:shared_preferences/shared_preferences.dart';

/// 권장 업데이트 안내 노출 주기: 마지막 노출 시각 저장, 주기 경과 여부 판정
class RecommendedUpdatePromptService {
  // SharedPreferences: 권장 업데이트 안내 마지막 노출 시각 (epoch ms)
  static const String _lastShownAtKey = 'recommended_update_prompt_last_shown_at';
  // 같은 안내 재노출 간격 (닫은 뒤 매 실행마다 뜨지 않게)
  static const Duration promptInterval = Duration(days: 3);

  final DateTime Function() _now;

  RecommendedUpdatePromptService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// 노출 기록 없음 또는 마지막 노출 후 주기 경과 > 노출
  static bool isPromptDue({required DateTime? lastShownAt, required DateTime now}) {
    if (lastShownAt == null) return true;
    return now.difference(lastShownAt) >= promptInterval;
  }

  Future<bool> shouldShowPrompt() async {
    final preferences = await SharedPreferences.getInstance();
    final lastShownAtMilliseconds = preferences.getInt(_lastShownAtKey);
    final lastShownAt = lastShownAtMilliseconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(lastShownAtMilliseconds);
    return isPromptDue(lastShownAt: lastShownAt, now: _now());
  }

  Future<void> markPromptShown() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_lastShownAtKey, _now().millisecondsSinceEpoch);
  }
}
