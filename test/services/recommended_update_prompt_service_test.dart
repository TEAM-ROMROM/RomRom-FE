import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/services/recommended_update_prompt_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 권장 업데이트 안내 주기: 처음 > 노출, 마지막 노출 후 주기 경과 전 > 생략
void main() {
  final now = DateTime(2026, 11, 3, 12);

  test('노출 기록 없음 > 노출', () {
    expect(RecommendedUpdatePromptService.isPromptDue(lastShownAt: null, now: now), isTrue);
  });

  test('주기 경과 전 > 생략, 경과 후 > 노출', () {
    const interval = RecommendedUpdatePromptService.promptInterval;
    expect(
      RecommendedUpdatePromptService.isPromptDue(
        lastShownAt: now.subtract(interval - const Duration(minutes: 1)),
        now: now,
      ),
      isFalse,
    );
    expect(RecommendedUpdatePromptService.isPromptDue(lastShownAt: now.subtract(interval), now: now), isTrue);
  });

  test('노출 기록 저장 > 같은 시각 재판정 시 생략', () async {
    SharedPreferences.setMockInitialValues({});
    final service = RecommendedUpdatePromptService(now: () => now);

    expect(await service.shouldShowPrompt(), isTrue);
    await service.markPromptShown();
    expect(await service.shouldShowPrompt(), isFalse);
  });
}
