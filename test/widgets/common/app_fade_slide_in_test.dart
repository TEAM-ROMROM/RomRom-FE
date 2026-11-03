import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/widgets/common/app_fade_slide_in.dart';

/// 등장 애니메이션 지연 상한 검증: 긴 지연 요청도 최대 지연 뒤 시작
void main() {
  double readOpacity(WidgetTester tester) => tester.widget<FadeTransition>(find.byType(FadeTransition)).opacity.value;

  testWidgets('40번째 항목 지연(1200ms) 요청 > 최대 지연(240ms) 뒤 시작해 끝까지 등장', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AppFadeSlideIn(
          delay: Duration(milliseconds: 40 * AppMotion.staggerDelayMs),
          child: Text('item'),
        ),
      ),
    );

    // 최대 지연 직전: 아직 투명
    await tester.pump(AppMotion.maximumStaggerDelay - const Duration(milliseconds: 1));
    expect(readOpacity(tester), 0.0);

    // 최대 지연 + 애니메이션 시간 뒤: 완전히 보임 (요청 지연 1200ms 이전)
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(AppMotion.normal);
    expect(readOpacity(tester), 1.0);
  });

  testWidgets('최대 지연보다 짧은 지연은 그대로', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AppFadeSlideIn(
          delay: Duration(milliseconds: 3 * AppMotion.staggerDelayMs),
          child: Text('item'),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 89));
    expect(readOpacity(tester), 0.0);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(AppMotion.normal);
    expect(readOpacity(tester), 1.0);
  });
}
