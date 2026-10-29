import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/providers/member_block_provider.dart';
import 'package:romrom_fe/repositories/member_block_repository.dart';

class FakeMemberBlockRepository implements MemberBlockRepository {
  bool throwOnBlock = false;
  bool throwOnUnblock = false;
  bool blockReturn = true;
  bool unblockReturn = true;
  int blockCalls = 0;
  int unblockCalls = 0;

  @override
  Future<bool> block(String memberId) async {
    blockCalls++;
    if (throwOnBlock) throw Exception('boom');
    return blockReturn;
  }

  @override
  Future<bool> unblock(String memberId) async {
    unblockCalls++;
    if (throwOnUnblock) throw Exception('boom');
    return unblockReturn;
  }
}

void main() {
  // navigatorKey.currentContext(GlobalKey) 접근이 바인딩을 요구하므로 초기화
  TestWidgetsFlutterBinding.ensureInitialized();

  group('memberBlockProvider', () {
    late FakeMemberBlockRepository fake;
    late ProviderContainer container;

    setUp(() {
      fake = FakeMemberBlockRepository();
      container = ProviderContainer(overrides: [memberBlockRepositoryProvider.overrideWithValue(fake)]);
    });

    tearDown(() => container.dispose());

    test('seed 후 setBlocked(false)는 즉시 Set에서 제거한다', () async {
      final n = container.read(memberBlockProvider.notifier);
      n.seed({'A', 'B'});
      final f = n.setBlocked('A', false);
      expect(container.read(memberBlockProvider).isBlocked('A'), isFalse);
      await f;
      expect(fake.unblockCalls, 1);
    });

    test('차단 해제 실패 시 prev로 롤백', () async {
      final n = container.read(memberBlockProvider.notifier);
      n.seed({'A'});
      fake.throwOnUnblock = true;
      await n.setBlocked('A', false);
      expect(container.read(memberBlockProvider).isBlocked('A'), isTrue);
    });

    test('서버 응답이 false인 경우도 롤백', () async {
      final n = container.read(memberBlockProvider.notifier);
      n.seed({'A'});
      fake.unblockReturn = false;
      await n.setBlocked('A', false);
      expect(container.read(memberBlockProvider).isBlocked('A'), isTrue);
    });

    test('차단 추가 setBlocked(true)는 즉시 Set에 추가', () async {
      final n = container.read(memberBlockProvider.notifier);
      n.seed({});
      final f = n.setBlocked('B', true);
      expect(container.read(memberBlockProvider).isBlocked('B'), isTrue);
      await f;
      expect(fake.blockCalls, 1);
    });

    test('setBlocked는 서버 확정 시 true를 반환한다', () async {
      final isBlockSucceeded = await container.read(memberBlockProvider.notifier).setBlocked('B', true);
      expect(isBlockSucceeded, isTrue);
    });

    test('setBlocked는 실패·서버 false 시 false를 반환한다 (호출부 성공 처리 차단용)', () async {
      final notifier = container.read(memberBlockProvider.notifier);
      fake.throwOnBlock = true;
      expect(await notifier.setBlocked('B', true), isFalse);
      fake.unblockReturn = false;
      expect(await notifier.setBlocked('A', false), isFalse);
    });
  });
}
