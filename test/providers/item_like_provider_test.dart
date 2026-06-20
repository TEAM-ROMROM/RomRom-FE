import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/providers/item_like_provider.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/states/item_like_state.dart';

class FakeItemRepository implements ItemRepository {
  bool shouldThrow = false;
  bool? returnLiked;
  int? returnCount;
  int callCount = 0;

  /// postLike 응답을 보류시켜 in-flight 상태를 테스트에서 제어 (연타 큐잉 검증용)
  Completer<ItemResponse>? gate;

  @override
  Future<ItemResponse> postLike(String itemId) async {
    callCount++;
    if (shouldThrow) throw Exception('boom');
    // 게이트가 열려 있으면 그 응답을 기다린다 (in-flight 유지)
    if (gate != null) {
      final res = await gate!.future;
      gate = null;
      return res;
    }
    return ItemResponse(
      isLiked: returnLiked,
      item: Item(itemId: itemId, likeCount: returnCount),
    );
  }

  @override
  Future<List<Item>> getMyItems(ItemStatus status, {int pageSize = 100}) async => const [];

  @override
  Future<ItemResponse> postItem(ItemRequest request) async => throw UnimplementedError();

  @override
  Future<void> deleteItem(String itemId) async => throw UnimplementedError();

  @override
  Future<ItemResponse> updateItemStatus(ItemRequest request) async => throw UnimplementedError();
}

void main() {
  // navigatorKey.currentContext(GlobalKey) 접근이 바인딩을 요구하므로 초기화
  TestWidgetsFlutterBinding.ensureInitialized();

  group('itemLikeProvider', () {
    late FakeItemRepository fake;
    late ProviderContainer container;

    setUp(() {
      fake = FakeItemRepository();
      container = ProviderContainer(overrides: [itemRepositoryProvider.overrideWithValue(fake)]);
      // 본인글 체크는 cachedMemberId(UserInfo 싱글톤)를 보므로 테스트마다 초기화
      UserInfo().memberId = null;
    });

    tearDown(() {
      container.dispose();
      UserInfo().memberId = null;
    });

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

    test('연타: 진행 중 추가 탭은 무시되지 않고 UI에 즉시 반영된다', () async {
      final notifier = container.read(itemLikeProvider.notifier);
      notifier.seed(itemId: 'A', isLiked: false, likeCount: 0);

      // 첫 요청을 게이트로 묶어 in-flight 유지
      fake.gate = Completer<ItemResponse>();
      final f1 = notifier.toggle('A'); // false→true (요청A 시작)
      expect(container.read(itemLikeProvider)['A']?.isLiked, isTrue);

      // 진행 중 두 번째 탭: 큐잉 + UI 즉시 반영 (true→false)
      final f2 = notifier.toggle('A');
      expect(container.read(itemLikeProvider)['A']?.isLiked, isFalse);

      // 요청A 응답: 서버는 true(좋아요) 확정
      fake.gate!.complete(ItemResponse(isLiked: true, item: Item(itemId: 'A', likeCount: 1)));
      fake.returnLiked = false; // 보정 요청은 false(취소) 확정
      fake.returnCount = 0;
      await Future.wait([f1, f2]);

      // 최종 의도(취소)와 일치 + 보정 요청 1회 발생 → 총 2회 호출
      expect(container.read(itemLikeProvider)['A']?.isLiked, isFalse);
      expect(fake.callCount, 2);
    });

    test('연타 후 최종 의도가 서버 확정값과 같으면 보정 요청을 안 한다', () async {
      final notifier = container.read(itemLikeProvider.notifier);
      notifier.seed(itemId: 'A', isLiked: false, likeCount: 0);

      fake.gate = Completer<ItemResponse>();
      final f1 = notifier.toggle('A'); // false→true
      final f2 = notifier.toggle('A'); // true→false (큐잉)
      final f3 = notifier.toggle('A'); // false→true (큐잉, 최종 의도=true)
      expect(container.read(itemLikeProvider)['A']?.isLiked, isTrue);

      // 요청A 응답: 서버도 true → 최종 의도와 일치 → 보정 skip
      fake.gate!.complete(ItemResponse(isLiked: true, item: Item(itemId: 'A', likeCount: 1)));
      await Future.wait([f1, f2, f3]);

      expect(container.read(itemLikeProvider)['A']?.isLiked, isTrue);
      expect(fake.callCount, 1); // 보정 없음
    });

    test('본인 게시글이면 toggle이 무시되고 상태가 변하지 않는다', () async {
      UserInfo().memberId = 'me';
      final notifier = container.read(itemLikeProvider.notifier);
      notifier.seed(itemId: 'A', isLiked: false, likeCount: 0);

      await notifier.toggle('A', authorMemberId: 'me');

      expect(container.read(itemLikeProvider)['A'], const ItemLikeState(isLiked: false, likeCount: 0));
      expect(fake.callCount, 0);
    });

    test('타인 게시글이면 authorMemberId가 있어도 정상 toggle된다', () async {
      UserInfo().memberId = 'me';
      final notifier = container.read(itemLikeProvider.notifier);
      notifier.seed(itemId: 'A', isLiked: false, likeCount: 0);

      fake.returnLiked = true;
      fake.returnCount = 1;
      await notifier.toggle('A', authorMemberId: 'other');

      expect(container.read(itemLikeProvider)['A']?.isLiked, isTrue);
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
