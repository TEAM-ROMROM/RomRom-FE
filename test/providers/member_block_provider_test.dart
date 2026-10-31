import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/providers/member_block_provider.dart';
import 'package:romrom_fe/repositories/member_block_repository.dart';

class FakeMemberBlockRepository implements MemberBlockRepository {
  bool throwOnBlock = false;
  bool throwOnUnblock = false;
  bool blockReturn = true;
  bool unblockReturn = true;
  int blockCalls = 0;
  int unblockCalls = 0;
  int getBlockedMembersCalls = 0;
  bool throwOnGetBlockedMembers = false;
  List<Member> serverBlockedMembers = [];

  // 설정 시 block 응답이 이 완료 신호를 기다림 (진행 중 상태 재현)
  Completer<bool>? blockGate;

  @override
  Future<bool> block(String memberId) async {
    blockCalls++;
    final gate = blockGate;
    if (gate != null) return gate.future;
    if (throwOnBlock) throw Exception('boom');
    return blockReturn;
  }

  @override
  Future<bool> unblock(String memberId) async {
    unblockCalls++;
    if (throwOnUnblock) throw Exception('boom');
    return unblockReturn;
  }

  @override
  Future<List<Member>> getBlockedMembers() async {
    getBlockedMembersCalls++;
    if (throwOnGetBlockedMembers) throw Exception('boom');
    return serverBlockedMembers;
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

    test('fetchBlockedMembers는 서버 목록 반환 + 차단 id로 강제 시드 (id 없는 회원 제외)', () async {
      final notifier = container.read(memberBlockProvider.notifier);
      notifier.seed({'OLD'});
      fake.serverBlockedMembers = [Member(memberId: 'A'), Member(memberId: 'B'), Member()];

      final blockedMembers = await notifier.fetchBlockedMembers();

      expect(blockedMembers.length, 3);
      expect(fake.getBlockedMembersCalls, 1);
      expect(container.read(memberBlockProvider).blockedIds, {'A', 'B'});
    });

    test('fetchBlockedMembers 실패 시 예외 전달 + 기존 차단 상태 유지', () async {
      final notifier = container.read(memberBlockProvider.notifier);
      notifier.seed({'A'});
      fake.throwOnGetBlockedMembers = true;

      await expectLater(notifier.fetchBlockedMembers(), throwsException);
      expect(container.read(memberBlockProvider).blockedIds, {'A'});
    });

    test('세션 초기화(invalidate) 후 > 이전 세션 진행 중 차단이 새 차단 요청을 막지 않음', () async {
      fake.blockGate = Completer<bool>();
      final previousSessionBlock = container.read(memberBlockProvider.notifier).setBlocked('A', true);

      container.invalidate(memberBlockProvider);
      expect(container.read(memberBlockProvider).blockedIds, isEmpty);
      final nextSessionBlock = container.read(memberBlockProvider.notifier).setBlocked('A', true);

      expect(fake.blockCalls, 2);
      fake.blockGate!.complete(true);
      await Future.wait([previousSessionBlock, nextSessionBlock]);
    });
  });
}
