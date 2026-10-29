import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/services/chat_member_status_poller.dart';

void main() {
  group('ChatMemberStatusPoller 생명주기', () {
    late int fetchCount;
    late ChatMemberStatusPoller poller;

    setUp(() {
      fetchCount = 0;
      poller = ChatMemberStatusPoller.forTest(
        fetchMemberProfile: (memberId) async {
          fetchCount++;
          return Member(memberId: memberId);
        },
      );
    });

    testWidgets('paused 동안 폴링 중단, resumed 시 즉시 1회 조회 후 주기 재개', (tester) async {
      poller.start('opponent');
      await tester.pump();
      expect(fetchCount, 1, reason: '진입 즉시 1회');

      await tester.pump(ChatMemberStatusPoller.pollInterval);
      expect(fetchCount, 2);

      poller.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump(ChatMemberStatusPoller.pollInterval * 3);
      expect(fetchCount, 2, reason: '백그라운드에서는 조회하지 않음');

      poller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(fetchCount, 3, reason: '복귀 즉시 1회');

      await tester.pump(ChatMemberStatusPoller.pollInterval);
      expect(fetchCount, 4, reason: '복귀 후 주기 재개');

      poller.dispose(); // 대기 타이머 정리
    });

    testWidgets('inactive는 폴링을 중단하지 않음', (tester) async {
      poller.start('opponent');
      await tester.pump();

      poller.didChangeAppLifecycleState(AppLifecycleState.inactive);
      await tester.pump(ChatMemberStatusPoller.pollInterval);

      expect(fetchCount, 2);
      poller.dispose();
    });

    testWidgets('stop 이후 resumed가 와도 조회하지 않음', (tester) async {
      poller.start('opponent');
      await tester.pump();
      poller.stop();

      poller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump(ChatMemberStatusPoller.pollInterval * 2);

      expect(fetchCount, 1);
      poller.dispose();
    });
  });
}
