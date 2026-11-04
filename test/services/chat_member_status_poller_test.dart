import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/services/chat_member_status_poller.dart';

void main() {
  group('ChatMemberStatusPoller 생명주기', () {
    late int fetchCount;
    late ChatMemberStatusPoller poller;
    final Object roomScreen = Object();

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
      poller.start('opponent', owner: roomScreen);
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
      poller.start('opponent', owner: roomScreen);
      await tester.pump();

      poller.didChangeAppLifecycleState(AppLifecycleState.inactive);
      await tester.pump(ChatMemberStatusPoller.pollInterval);

      expect(fetchCount, 2);
      poller.dispose();
    });

    testWidgets('stop 이후 resumed가 와도 조회하지 않음', (tester) async {
      poller.start('opponent', owner: roomScreen);
      await tester.pump();
      poller.stop(owner: roomScreen);

      poller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump(ChatMemberStatusPoller.pollInterval * 2);

      expect(fetchCount, 1);
      poller.dispose();
    });
  });

  group('ChatMemberStatusPoller 화면별 소유 (같은·다른 채팅방 겹침)', () {
    late List<String> fetchedMemberIds;
    late ChatMemberStatusPoller poller;
    final Object lowerRoomScreen = Object();
    final Object upperRoomScreen = Object();

    setUp(() {
      fetchedMemberIds = [];
      poller = ChatMemberStatusPoller.forTest(
        fetchMemberProfile: (memberId) async {
          fetchedMemberIds.add(memberId);
          return Member(memberId: memberId);
        },
      );
    });

    testWidgets('위 화면 종료 > 아래 화면 상대 폴링 즉시 재개 (아래 화면 폴링 유지)', (tester) async {
      poller.start('opponent-lower', owner: lowerRoomScreen);
      poller.start('opponent-upper', owner: upperRoomScreen);
      await tester.pump();
      fetchedMemberIds.clear();

      poller.stop(owner: upperRoomScreen);
      await tester.pump();
      expect(fetchedMemberIds, ['opponent-lower'], reason: '아래 화면 상대 즉시 1회');

      await tester.pump(ChatMemberStatusPoller.pollInterval);
      expect(fetchedMemberIds, ['opponent-lower', 'opponent-lower'], reason: '주기 재개');
      poller.dispose();
    });

    testWidgets('아래 화면 종료 > 위 화면 폴링 영향 없음', (tester) async {
      poller.start('opponent-lower', owner: lowerRoomScreen);
      poller.start('opponent-upper', owner: upperRoomScreen);
      await tester.pump();
      fetchedMemberIds.clear();

      poller.stop(owner: lowerRoomScreen);
      await tester.pump(ChatMemberStatusPoller.pollInterval);

      expect(fetchedMemberIds, ['opponent-upper']);
      poller.dispose();
    });

    testWidgets('streamOf는 요청한 회원 결과만 전달 (다른 화면 상대 제외)', (tester) async {
      final receivedMemberIds = <String?>[];
      final subscription = poller.streamOf('opponent-lower').listen((member) => receivedMemberIds.add(member.memberId));

      poller.start('opponent-upper', owner: upperRoomScreen);
      await tester.pump();
      poller.start('opponent-lower', owner: lowerRoomScreen);
      await tester.pump();

      expect(receivedMemberIds, ['opponent-lower']);
      // fake async 안 취소 완료 대기 없음 (await 시 멈춤)
      unawaited(subscription.cancel());
      poller.dispose();
    });
  });
}
