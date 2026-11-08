import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/rewarded_ad_outcome.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/item_promotion_eligibility.dart';
import 'package:romrom_fe/providers/promotion_repository_provider.dart';
import 'package:romrom_fe/repositories/promotion_repository.dart';
import 'package:romrom_fe/services/rewarded_ad_service.dart';
import 'package:romrom_fe/widgets/my_page/my_item_promote_control.dart';

import '../../helpers/pump_design_screen.dart';

// 남은 시간 계산 기준 시각
final referenceTime = DateTime(2026, 10, 31, 12);

/// 보상형 광고 대역: 표시 횟수 기록, 보상 미적립으로 끝냄 (서버 호출 없이 종료)
class _CountingRewardedAdService extends RewardedAdService {
  int showCount = 0;

  @override
  Future<void> load() async {}

  @override
  Future<RewardedAdOutcome> showAndAwaitReward() async {
    showCount++;
    return RewardedAdOutcome.notEarned;
  }
}

/// 우선노출 저장소 대역: 사전 자격 판단 불가(null) > 광고 진행 (서버 호출 없음)
class _UnknownEligibilityPromotionRepository implements PromotionRepository {
  @override
  Future<ItemPromotionEligibility?> getEligibility(String itemId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> pumpPromoteControl(
  WidgetTester tester,
  Item item, {
  DateTime Function()? clock,
  RewardedAdService? rewardedAdService,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (rewardedAdService != null) rewardedAdServiceProvider.overrideWithValue(rewardedAdService),
        promotionRepositoryProvider.overrideWithValue(_UnknownEligibilityPromotionRepository()),
      ],
      child: buildDesignScreenApp(
        home: Scaffold(
          body: MyItemPromoteControl(item: item, clock: clock ?? () => referenceTime),
        ),
      ),
    ),
  );
}

void main() {
  group('MyItemPromoteControl 노출 배지', () {
    testWidgets('종료 시각이 미래 > 남은 시간 배지, 우선 노출 버튼 없음', (tester) async {
      await pumpPromoteControl(
        tester,
        Item(
          itemId: 'A',
          isPromoted: true,
          promotionExpiresAt: referenceTime.add(const Duration(hours: 23, minutes: 40)),
        ),
      );

      expect(find.text('⚡ 노출 중 · 23시간 남음'), findsOneWidget);
      expect(find.text('⚡ 우선 노출'), findsNothing);
    });

    testWidgets('종료 시각 지남 > 배지 숨김, 우선 노출 버튼 (isPromoted true여도)', (tester) async {
      await pumpPromoteControl(
        tester,
        Item(itemId: 'A', isPromoted: true, promotionExpiresAt: referenceTime.subtract(const Duration(minutes: 1))),
      );

      expect(find.textContaining('노출 중'), findsNothing);
      expect(find.text('⚡ 우선 노출'), findsOneWidget);
    });

    testWidgets('종료 시각 없음 + isPromoted true > 문구만 배지', (tester) async {
      await pumpPromoteControl(tester, Item(itemId: 'A', isPromoted: true));

      expect(find.text('⚡ 노출 중'), findsOneWidget);
    });

    testWidgets('노출 이력 없음 > 우선 노출 버튼', (tester) async {
      await pumpPromoteControl(tester, Item(itemId: 'A'));

      expect(find.text('⚡ 우선 노출'), findsOneWidget);
    });

    testWidgets('itemId 없음 > 아무것도 표시 안 함', (tester) async {
      await pumpPromoteControl(tester, Item(isPromoted: true));

      expect(find.textContaining('노출'), findsNothing);
    });
  });

  group('toPromotionActiveLabel 남은 시간 문구', () {
    test('1시간 이상 > 시간 (버림), 1시간 미만 > 분 (최소 1분), 없음 > 문구만', () {
      expect(MyItemPromoteControl.toPromotionActiveLabel(const Duration(hours: 24)), '⚡ 노출 중 · 24시간 남음');
      expect(MyItemPromoteControl.toPromotionActiveLabel(const Duration(hours: 1, minutes: 59)), '⚡ 노출 중 · 1시간 남음');
      expect(MyItemPromoteControl.toPromotionActiveLabel(const Duration(minutes: 59)), '⚡ 노출 중 · 59분 남음');
      expect(MyItemPromoteControl.toPromotionActiveLabel(const Duration(seconds: 20)), '⚡ 노출 중 · 1분 남음');
      expect(MyItemPromoteControl.toPromotionActiveLabel(null), '⚡ 노출 중');
    });
  });

  group('MyItemPromoteControl 만료·확인 창 (#969)', () {
    testWidgets('노출 중 만료 시각이 지나면 다시 그려 우선 노출 버튼 표시', (tester) async {
      var currentTime = referenceTime;
      await pumpPromoteControl(
        tester,
        Item(itemId: 'A', isPromoted: true, promotionExpiresAt: referenceTime.add(const Duration(seconds: 30))),
        clock: () => currentTime,
      );
      expect(find.text('⚡ 노출 중 · 1분 남음'), findsOneWidget);

      currentTime = referenceTime.add(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 31));

      expect(find.textContaining('노출 중'), findsNothing);
      expect(find.text('⚡ 우선 노출'), findsOneWidget);
    });

    testWidgets('우선 노출 탭 > 확인 창(하루 횟수 안내), 취소하면 광고 시작 안 함', (tester) async {
      final rewardedAdService = _CountingRewardedAdService();
      await pumpPromoteControl(tester, Item(itemId: 'A'), rewardedAdService: rewardedAdService);

      await tester.tap(find.text('⚡ 우선 노출'));
      await tester.pumpAndSettle();
      expect(find.textContaining('하루 3회'), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(rewardedAdService.showCount, 0);
    });

    testWidgets('확인 창에서 광고 보기 > 광고 시작', (tester) async {
      final rewardedAdService = _CountingRewardedAdService();
      await pumpPromoteControl(tester, Item(itemId: 'A'), rewardedAdService: rewardedAdService);

      await tester.tap(find.text('⚡ 우선 노출'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('광고 보기'));
      await tester.pumpAndSettle();

      expect(rewardedAdService.showCount, 1);
      // 토스트 표시 시간 + 닫힘 애니메이션 소진
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });
  });
}
