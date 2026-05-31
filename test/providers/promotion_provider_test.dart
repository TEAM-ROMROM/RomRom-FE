import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/promote_result.dart';
import 'package:romrom_fe/providers/promotion_provider.dart';
import 'package:romrom_fe/providers/promotion_repository_provider.dart';
import 'package:romrom_fe/repositories/promotion_repository.dart';
import 'package:romrom_fe/services/rewarded_ad_service.dart';

// 광고 서비스는 public 생성자라 extends 가능 — 보상 결과를 주입한다.
class FakeRewardedAdService extends RewardedAdService {
  bool reward = true;
  int showCount = 0;
  @override
  Future<void> load() async {}
  @override
  Future<bool> showAndAwaitReward() async {
    showCount++;
    return reward;
  }
}

// PromotionApi는 싱글톤(private 생성자)이라 subclass 불가 → repository를 통째로 fake.
class FakePromotionRepository implements PromotionRepository {
  bool shouldThrow = false;
  int activateCount = 0;
  @override
  Future<void> activate(String itemId) async {
    activateCount++;
    if (shouldThrow) throw Exception('boom');
  }
}

void main() {
  group('promotionProvider', () {
    late FakeRewardedAdService ad;
    late FakePromotionRepository repo;
    late ProviderContainer container;

    setUp(() {
      ad = FakeRewardedAdService();
      repo = FakePromotionRepository();
      container = ProviderContainer(
        overrides: [
          rewardedAdServiceProvider.overrideWithValue(ad),
          promotionRepositoryProvider.overrideWithValue(repo),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('보상 O + BE 성공 → success, state에 itemId 포함', () async {
      ad.reward = true;
      final result = await container.read(promotionProvider.notifier).promoteItem('A');
      expect(result, PromoteResult.success);
      expect(container.read(promotionProvider).isPromoted('A'), isTrue);
      expect(repo.activateCount, 1);
    });

    test('보상 X → adNotEarned, state 변화 없음, BE 미호출', () async {
      ad.reward = false;
      final result = await container.read(promotionProvider.notifier).promoteItem('A');
      expect(result, PromoteResult.adNotEarned);
      expect(container.read(promotionProvider).isPromoted('A'), isFalse);
      expect(repo.activateCount, 0);
    });

    test('보상 O + BE 실패 → failed, state 변화 없음', () async {
      ad.reward = true;
      repo.shouldThrow = true;
      final result = await container.read(promotionProvider.notifier).promoteItem('A');
      expect(result, PromoteResult.failed);
      expect(container.read(promotionProvider).isPromoted('A'), isFalse);
    });

    test('진행 중 동일 itemId 재호출 → alreadyInFlight (광고 1회만)', () async {
      ad.reward = true;
      final f1 = container.read(promotionProvider.notifier).promoteItem('A');
      final f2 = container.read(promotionProvider.notifier).promoteItem('A');
      final results = await Future.wait([f1, f2]);
      expect(results, containsAll([PromoteResult.success, PromoteResult.alreadyInFlight]));
      expect(ad.showCount, 1);
    });
  });
}
