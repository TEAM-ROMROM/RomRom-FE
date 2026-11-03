import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/sent_requests_reload_policy.dart';

void main() {
  final loadedAt = DateTime(2026, 11, 3, 12);
  const minimumInterval = Duration(seconds: 10);

  SentRequestsReloadPolicy buildPolicy() => SentRequestsReloadPolicy(minimumBackgroundReloadInterval: minimumInterval);

  group('카드 로드 시 보낸 요청 조회 여부', () {
    test('전체 조회 기록 없음 > 조회', () {
      expect(buildPolicy().shouldLoadForItems(const ['a'], isForced: false), isTrue);
    });

    test('마지막 전체 조회와 같은 카드 목록 > 생략, 강제 > 조회', () {
      final policy = buildPolicy()..recordFullLoad(const ['a', 'b'], startedAt: loadedAt);

      expect(policy.shouldLoadForItems(const ['a', 'b'], isForced: false), isFalse);
      expect(policy.shouldLoadForItems(const ['a', 'b'], isForced: true), isTrue);
    });

    test('카드 목록 다름(추가·삭제·순서) > 조회', () {
      final policy = buildPolicy()..recordFullLoad(const ['a', 'b'], startedAt: loadedAt);

      expect(policy.shouldLoadForItems(const ['a'], isForced: false), isTrue);
      expect(policy.shouldLoadForItems(const ['b', 'a'], isForced: false), isTrue);
    });
  });

  group('백그라운드 재조회(탭 진입·앱 복귀) 여부', () {
    test('전체 조회 기록 없음(요청관리 첫 로드 전) > 생략', () {
      expect(buildPolicy().shouldReloadInBackground(loadedAt.add(const Duration(hours: 1))), isFalse);
    });

    test('마지막 전체 조회 시작 후 최소 간격 미만 > 생략, 이상 > 조회', () {
      final policy = buildPolicy()..recordFullLoad(const ['a'], startedAt: loadedAt);

      expect(policy.shouldReloadInBackground(loadedAt.add(const Duration(seconds: 9))), isFalse);
      expect(policy.shouldReloadInBackground(loadedAt.add(minimumInterval)), isTrue);
    });

    test('초기화(세션 전환) > 기록 없음 상태', () {
      final policy = buildPolicy()
        ..recordFullLoad(const ['a'], startedAt: loadedAt)
        ..reset();

      expect(policy.shouldLoadForItems(const ['a'], isForced: false), isTrue);
      expect(policy.shouldReloadInBackground(loadedAt.add(const Duration(hours: 1))), isFalse);
    });
  });
}
