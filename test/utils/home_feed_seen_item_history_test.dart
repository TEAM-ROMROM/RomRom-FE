import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/home_feed_seen_item_history.dart';

/// 홈 피드 본 물품 기록: 최근 100개 유지, 묶음 저장, 즉시 저장(flush), 기록 시점 회원 키로 저장
void main() {
  late List<List<String>> savedSnapshots;
  late List<String> savedMemberIds;
  String? currentMemberId;

  // 테스트용 묶음 저장 지연 (실제 기본값 2초 대신)
  const testSaveDelay = Duration(milliseconds: 30);

  // 테스트 끝에 예약 저장 정리 (다음 테스트 기록에 섞임 방지)
  HomeFeedSeenItemHistory buildHistory({Iterable<String> restoredSeenItemIds = const []}) {
    final history = HomeFeedSeenItemHistory(
      saveSeenItemIds: (seenItemIds, {required memberId}) async {
        savedSnapshots.add(List.of(seenItemIds));
        savedMemberIds.add(memberId);
      },
      readCurrentMemberId: () async => currentMemberId,
      restoredSeenItemIds: restoredSeenItemIds,
      saveDelay: testSaveDelay,
    );
    addTearDown(history.flush);
    return history;
  }

  setUp(() {
    savedSnapshots = [];
    savedMemberIds = [];
    currentMemberId = 'member-a';
  });

  test('복원: 최대치 초과면 최근 것만, 오래된 순 유지', () {
    final history = buildHistory(
      restoredSeenItemIds: List.generate(HomeFeedSeenItemHistory.maximumSeenItemCount + 3, (index) => 'id-$index'),
    );

    expect(history.seenItemIds.length, HomeFeedSeenItemHistory.maximumSeenItemCount);
    expect(history.seenItemIds.first, 'id-3');
    expect(history.seenItemIds.last, 'id-${HomeFeedSeenItemHistory.maximumSeenItemCount + 2}');
  });

  test('markSeen: 다시 본 물품은 최근으로, 최대치 넘으면 가장 오래된 것 제거', () {
    final history = buildHistory();
    for (var index = 0; index < HomeFeedSeenItemHistory.maximumSeenItemCount + 2; index++) {
      history.markSeen('id-$index');
    }
    history.markSeen('id-5');

    expect(history.seenItemIds.length, HomeFeedSeenItemHistory.maximumSeenItemCount);
    expect(history.seenItemIds.contains('id-0'), false);
    expect(history.seenItemIds.contains('id-1'), false);
    expect(history.seenItemIds.last, 'id-5');
  });

  test('묶음 저장: 첫 기록 후 지연 시간 뒤 1회만 저장 (그 사이 기록 모두 포함)', () async {
    final history = buildHistory();
    history.markSeen('a');
    history.markSeen('b');
    history.markSeen('a');

    expect(savedSnapshots, isEmpty, reason: '넘길 때마다 저장하지 않음');
    await Future<void>.delayed(testSaveDelay * 3);

    expect(savedSnapshots, [
      ['b', 'a'],
    ]);
  });

  test('flush: 대기 중 기록 즉시 저장 + 예약 취소 (같은 내용 두 번 저장 안 함)', () async {
    final history = buildHistory();
    history.markSeen('a');

    await history.flush();
    await Future<void>.delayed(testSaveDelay * 3);

    expect(savedSnapshots, [
      ['a'],
    ]);
  });

  test('flush: 저장할 변경 없으면 저장 안 함', () async {
    final history = buildHistory(restoredSeenItemIds: const ['a']);

    await history.flush();

    expect(savedSnapshots, isEmpty);
  });

  test('저장 시점에 회원 정보가 비어도 (세션 만료) 기록 시점 회원 키로 저장', () async {
    final history = buildHistory();
    history.markSeen('a');
    await Future<void>.delayed(Duration.zero);

    currentMemberId = null;
    await history.flush();

    expect(savedMemberIds, ['member-a']);
    expect(savedSnapshots, [
      ['a'],
    ]);
  });

  test('회원이 바뀐 뒤 기록은 다른 회원 키에 저장하지 않음 (이전 회원 기록 덮어쓰기 방지)', () async {
    final history = buildHistory();
    history.markSeen('a');
    await history.flush();

    currentMemberId = 'member-b';
    history.markSeen('b');
    await history.flush();

    expect(savedMemberIds, ['member-a'], reason: 'member-b 키에는 쓰지 않음');
  });

  test('기록 시점 회원 정보 없음 > 저장 안 함', () async {
    currentMemberId = null;
    final history = buildHistory();
    history.markSeen('a');

    await history.flush();

    expect(savedSnapshots, isEmpty);
  });
}
