import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/enums/promote_result.dart';
import 'package:romrom_fe/enums/rewarded_ad_outcome.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/exceptions/api_exception.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/providers/promotion_provider.dart';
import 'package:romrom_fe/providers/promotion_repository_provider.dart';
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/repositories/promotion_repository.dart';
import 'package:romrom_fe/services/rewarded_ad_service.dart';

/// 보상형 광고 대역: 표시 결과 지정, 표시 횟수 기록
class FakeRewardedAdService extends RewardedAdService {
  RewardedAdOutcome outcome = RewardedAdOutcome.earned;
  int showCount = 0;

  @override
  Future<void> load() async {}

  @override
  Future<RewardedAdOutcome> showAndAwaitReward() async {
    showCount++;
    return outcome;
  }
}

/// 우선노출 저장소 대역: 활성화 시 내 물건 서버 데이터에 노출 필드 반영, 예외 지정
class FakePromotionRepository implements PromotionRepository {
  FakePromotionRepository(this.itemRepository);

  final FakeItemRepository itemRepository;
  Object? errorToThrow;
  final List<String> promotedItemIds = [];

  @override
  Future<Item?> promote(String itemId) async {
    final error = errorToThrow;
    if (error != null) throw error;
    promotedItemIds.add(itemId);
    final expiresAt = DateTime.now().add(const Duration(hours: 24));
    itemRepository.available = itemRepository.available
        .map(
          (item) =>
              item.itemId == itemId ? Item(itemId: itemId, promotionExpiresAt: expiresAt, isPromoted: true) : item,
        )
        .toList();
    return Item(itemId: itemId, promotionExpiresAt: expiresAt, isPromoted: true);
  }
}

/// 물품 저장소 대역: 내 물건 조회만 (조회 횟수 기록)
class FakeItemRepository implements ItemRepository {
  List<Item> available = [Item(itemId: 'A')];
  int getMyItemsCount = 0;

  @override
  Future<List<Item>> getMyItems(ItemStatus status, {int pageSize = 100}) async {
    getMyItemsCount++;
    return status == ItemStatus.available ? available : const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ApiException buildApiException(int statusCode, String? errorCode) => ApiException(
  statusCode: statusCode,
  responseBody: errorCode == null ? '' : '{"errorCode":"$errorCode","errorMessage":"message"}',
);

void main() {
  group('promotionProvider 흐름', () {
    late FakeRewardedAdService rewardedAdService;
    late FakeItemRepository itemRepository;
    late FakePromotionRepository promotionRepository;
    late ProviderContainer container;

    setUp(() {
      rewardedAdService = FakeRewardedAdService();
      itemRepository = FakeItemRepository();
      promotionRepository = FakePromotionRepository(itemRepository);
      container = ProviderContainer(
        overrides: [
          rewardedAdServiceProvider.overrideWithValue(rewardedAdService),
          promotionRepositoryProvider.overrideWithValue(promotionRepository),
          itemRepositoryProvider.overrideWithValue(itemRepository),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('보상 적립 + 서버 성공 > success, 내 물건 서버 재조회로 노출 필드 반영', () async {
      await container.read(myItemsProvider.future);
      final fetchCountBeforePromote = itemRepository.getMyItemsCount;

      final result = await container.read(promotionProvider.notifier).promoteItem('A');

      expect(result, PromoteResult.success);
      expect(promotionRepository.promotedItemIds, ['A']);
      // 재조회 1회 = available + exchanged 2건
      expect(itemRepository.getMyItemsCount, fetchCountBeforePromote + 2);
      final promotedItem = container.read(myItemsProvider).valueOrNull!.available.single;
      expect(promotedItem.isPromoted, isTrue);
      expect(promotedItem.isPromotionActiveAt(DateTime.now()), isTrue);
      expect(container.read(promotionProvider).isPromoting('A'), isFalse);
    });

    test('시청 중 이탈 > adNotEarned, 서버 미호출', () async {
      rewardedAdService.outcome = RewardedAdOutcome.notEarned;

      final result = await container.read(promotionProvider.notifier).promoteItem('A');

      expect(result, PromoteResult.adNotEarned);
      expect(promotionRepository.promotedItemIds, isEmpty);
    });

    test('광고 미설정·로드 실패 > adUnavailable, 서버 미호출', () async {
      rewardedAdService.outcome = RewardedAdOutcome.unavailable;

      final result = await container.read(promotionProvider.notifier).promoteItem('A');

      expect(result, PromoteResult.adUnavailable);
      expect(promotionRepository.promotedItemIds, isEmpty);
    });

    test('서버 실패 > 결과 매핑, 내 물건 재조회 없음, 처리 중 상태 해제', () async {
      await container.read(myItemsProvider.future);
      final fetchCountBeforePromote = itemRepository.getMyItemsCount;
      promotionRepository.errorToThrow = buildApiException(429, 'ITEM_PROMOTION_DAILY_LIMIT_EXCEEDED');

      final result = await container.read(promotionProvider.notifier).promoteItem('A');

      expect(result, PromoteResult.dailyLimitExceeded);
      expect(itemRepository.getMyItemsCount, fetchCountBeforePromote);
      expect(container.read(promotionProvider).isPromoting('A'), isFalse);
    });

    test('처리 중 같은 itemId 재호출 > alreadyInFlight (광고 1회만), 처리 중 상태 노출', () async {
      final firstPromote = container.read(promotionProvider.notifier).promoteItem('A');
      expect(container.read(promotionProvider).isPromoting('A'), isTrue);
      final secondPromote = container.read(promotionProvider.notifier).promoteItem('A');

      final results = await Future.wait([firstPromote, secondPromote]);

      expect(results, [PromoteResult.success, PromoteResult.alreadyInFlight]);
      expect(rewardedAdService.showCount, 1);
    });
  });

  group('toPromoteFailureResult 오류 매핑', () {
    final expectedResultByError = <String, (ApiException, PromoteResult)>{
      '409 ITEM_PROMOTION_ALREADY_ACTIVE': (
        buildApiException(409, 'ITEM_PROMOTION_ALREADY_ACTIVE'),
        PromoteResult.alreadyPromoted,
      ),
      '429 ITEM_PROMOTION_DAILY_LIMIT_EXCEEDED': (
        buildApiException(429, 'ITEM_PROMOTION_DAILY_LIMIT_EXCEEDED'),
        PromoteResult.dailyLimitExceeded,
      ),
      '400 ITEM_NOT_PROMOTABLE': (buildApiException(400, 'ITEM_NOT_PROMOTABLE'), PromoteResult.notPromotable),
      '404 ITEM_NOT_FOUND': (buildApiException(404, 'ITEM_NOT_FOUND'), PromoteResult.failed),
      '403 INVALID_ITEM_OWNER': (buildApiException(403, 'INVALID_ITEM_OWNER'), PromoteResult.failed),
      '409 errorCode 없음': (buildApiException(409, null), PromoteResult.alreadyPromoted),
      '429 errorCode 없음': (buildApiException(429, null), PromoteResult.dailyLimitExceeded),
      '400 다른 errorCode': (buildApiException(400, 'INVALID_REQUEST'), PromoteResult.failed),
      '500 errorCode 없음': (buildApiException(500, null), PromoteResult.failed),
    };

    expectedResultByError.forEach((caseName, errorAndResult) {
      test('$caseName > ${errorAndResult.$2.name}', () {
        expect(toPromoteFailureResult(errorAndResult.$1), errorAndResult.$2);
      });
    });

    test('ApiException 아닌 예외 (네트워크 등) > failed', () {
      expect(toPromoteFailureResult(Exception('timeout')), PromoteResult.failed);
    });
  });

  group('PromoteResult 토스트 문구', () {
    test('결과별 문구·종류', () {
      expect(PromoteResult.alreadyPromoted.toastMessage, '이미 노출 중인 물품이에요');
      expect(PromoteResult.dailyLimitExceeded.toastMessage, '오늘은 우선 노출을 모두 사용했어요 (하루 3회)');
      expect(PromoteResult.notPromotable.toastMessage, '교환 가능한 물품만 노출할 수 있어요');
      expect(PromoteResult.failed.toastMessage, '잠시 후 다시 시도해주세요');
      expect(PromoteResult.failed.toastType, SnackBarType.error);
      expect(PromoteResult.success.toastType, SnackBarType.success);
    });

    test('중복 요청은 토스트 없음, 그 외 결과는 문구·종류 모두 있음', () {
      expect(PromoteResult.alreadyInFlight.toastMessage, isNull);
      expect(PromoteResult.alreadyInFlight.toastType, isNull);
      for (final result in PromoteResult.values.where((result) => result != PromoteResult.alreadyInFlight)) {
        expect(result.toastMessage, isNotNull, reason: result.name);
        expect(result.toastType, isNotNull, reason: result.name);
      }
    });
  });
}
