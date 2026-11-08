import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/services/push_open_reporter.dart';

void main() {
  late List<String> sentCampaignIds;
  late bool isMainScreenEntered;
  late bool shouldFailSend;
  late PushOpenReporter reporter;

  setUp(() {
    sentCampaignIds = [];
    isMainScreenEntered = true;
    shouldFailSend = false;
    reporter = PushOpenReporter(
      sendPushOpen: (campaignId) async {
        sentCampaignIds.add(campaignId);
        if (shouldFailSend) throw Exception('push open failed');
      },
      isMainScreenEntered: () => isMainScreenEntered,
    );
  });

  // 보내기 대기 (fire-and-forget 완료)
  Future<void> flushMicrotasks() => Future<void>.delayed(Duration.zero);

  group('PushOpenReporter (#1021)', () {
    test('캠페인 푸시 열림 > campaignId 1회 전송', () async {
      reporter.onPushOpened({'campaignId': 'campaign-1', 'deepLink': 'romrom://notice/detail'});
      await flushMicrotasks();

      expect(sentCampaignIds, ['campaign-1']);
    });

    test('campaignId 없음·빈 값·문자열 아님 > 전송 안 함', () async {
      reporter.onPushOpened({'notificationType': 'CHAT_MESSAGE_RECEIVED'});
      reporter.onPushOpened({'campaignId': ''});
      reporter.onPushOpened({'campaignId': 7});
      await flushMicrotasks();

      expect(sentCampaignIds, isEmpty);
    });

    test('같은 캠페인 중복 열림(콜드 스타트 + 탭 이벤트) > 1회만', () async {
      reporter.onPushOpened({'campaignId': 'campaign-1'});
      reporter.onPushOpened({'campaignId': 'campaign-1'});
      reporter.onPushOpened({'campaignId': 'campaign-2'});
      await flushMicrotasks();

      expect(sentCampaignIds, ['campaign-1', 'campaign-2']);
    });

    test('메인 진입 전 > 보관 후 진입 시 1회 전송', () async {
      isMainScreenEntered = false;
      reporter.onPushOpened({'campaignId': 'campaign-1'});
      await flushMicrotasks();
      expect(sentCampaignIds, isEmpty);

      isMainScreenEntered = true;
      reporter.onMainScreenEntered();
      reporter.onMainScreenEntered();
      await flushMicrotasks();

      expect(sentCampaignIds, ['campaign-1']);
    });

    test('전송 실패 > 예외 밖으로 안 나가고 재시도 없음', () async {
      shouldFailSend = true;
      reporter.onPushOpened({'campaignId': 'campaign-1'});
      await flushMicrotasks();
      reporter.onPushOpened({'campaignId': 'campaign-1'});
      await flushMicrotasks();

      expect(sentCampaignIds, ['campaign-1']);
    });
  });
}
