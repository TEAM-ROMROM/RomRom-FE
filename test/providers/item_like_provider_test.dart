import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/providers/item_like_provider.dart';
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/states/item_like_state.dart';

class FakeItemRepository implements ItemRepository {
  bool shouldThrow = false;
  bool? returnLiked;
  int? returnCount;
  int callCount = 0;

  @override
  Future<ItemResponse> postLike(String itemId) async {
    callCount++;
    if (shouldThrow) throw Exception('boom');
    return ItemResponse(
      isLiked: returnLiked,
      item: Item(itemId: itemId, likeCount: returnCount),
    );
  }
}

void main() {
  group('itemLikeProvider', () {
    late FakeItemRepository fake;
    late ProviderContainer container;

    setUp(() {
      fake = FakeItemRepository();
      container = ProviderContainer(overrides: [itemRepositoryProvider.overrideWithValue(fake)]);
    });

    tearDown(() => container.dispose());

    test('seed 후 toggle은 즉시 isLiked를 반전시킨다', () async {
      final notifier = container.read(itemLikeProvider.notifier);
      notifier.seed(itemId: 'A', isLiked: false, likeCount: 0);

      fake.returnLiked = true;
      fake.returnCount = 1;
      final future = notifier.toggle('A');

      // optimistic 적용 확인 (await 전)
      expect(container.read(itemLikeProvider)['A']?.isLiked, isTrue);
      expect(container.read(itemLikeProvider)['A']?.likeCount, 1);

      await future;
      // 서버 응답으로 보정
      expect(container.read(itemLikeProvider)['A'], const ItemLikeState(isLiked: true, likeCount: 1));
    });

    test('API 실패 시 prev로 롤백한다', () async {
      final notifier = container.read(itemLikeProvider.notifier);
      notifier.seed(itemId: 'A', isLiked: false, likeCount: 0);

      fake.shouldThrow = true;
      await notifier.toggle('A');

      expect(container.read(itemLikeProvider)['A'], const ItemLikeState(isLiked: false, likeCount: 0));
    });

    test('in-flight 중 toggle 재호출은 무시된다', () async {
      final notifier = container.read(itemLikeProvider.notifier);
      notifier.seed(itemId: 'A', isLiked: false, likeCount: 0);

      fake.returnLiked = true;
      fake.returnCount = 1;
      final f1 = notifier.toggle('A');
      final f2 = notifier.toggle('A');
      await Future.wait([f1, f2]);

      expect(fake.callCount, 1);
    });

    test('이미 시드된 항목에 force=false로 재시드 시 무시', () {
      final notifier = container.read(itemLikeProvider.notifier);
      notifier.seed(itemId: 'A', isLiked: true, likeCount: 5);
      notifier.seed(itemId: 'A', isLiked: false, likeCount: 0);
      expect(container.read(itemLikeProvider)['A']?.isLiked, isTrue);
    });

    test('force=true 재시드는 덮어쓴다', () {
      final notifier = container.read(itemLikeProvider.notifier);
      notifier.seed(itemId: 'A', isLiked: true, likeCount: 5);
      notifier.seed(itemId: 'A', isLiked: false, likeCount: 0, force: true);
      expect(container.read(itemLikeProvider)['A']?.isLiked, isFalse);
    });
  });
}
