import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/home_feed_ad_slot_schedule.dart';

/// nextInt 항상 고정값 (광고 간격 고정)
class _FixedRandom implements Random {
  final int fixedValue;

  _FixedRandom(this.fixedValue);

  @override
  int nextInt(int max) => fixedValue;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

void main() {
  group('HomeFeedAdSlotSchedule', () {
    test('첫 5개 광고 없음 > 간격 8마다 광고, 가상 index <-> 피드 index 변환', () {
      final adSlotSchedule = HomeFeedAdSlotSchedule(random: _FixedRandom(0));
      adSlotSchedule.scheduleAdsForFeedLength(20);

      // 광고 자리: 피드 5개 뒤(가상 5), 피드 13개 뒤(가상 14)
      expect(adSlotSchedule.virtualItemCount(20), 22);
      expect(adSlotSchedule.isAdAtVirtualIndex(4), false);
      expect(adSlotSchedule.isAdAtVirtualIndex(5), true);
      expect(adSlotSchedule.isAdAtVirtualIndex(14), true);
      expect(adSlotSchedule.feedIndexAtVirtualIndex(4), 4);
      expect(adSlotSchedule.feedIndexAtVirtualIndex(6), 5);
      expect(adSlotSchedule.feedIndexAtVirtualIndex(15), 13);
    });

    test('피드 늘면 기존 자리 유지하고 뒤에만 추가, reset 후 처음부터', () {
      final adSlotSchedule = HomeFeedAdSlotSchedule(random: _FixedRandom(3));
      adSlotSchedule.scheduleAdsForFeedLength(5);
      expect(adSlotSchedule.virtualItemCount(5), 5);

      adSlotSchedule.scheduleAdsForFeedLength(6);
      expect(adSlotSchedule.isAdAtVirtualIndex(5), true);

      // 간격 8 + 3 = 11 > 다음 광고는 피드 16개 뒤 (가상 17)
      adSlotSchedule.scheduleAdsForFeedLength(17);
      expect(adSlotSchedule.isAdAtVirtualIndex(17), true);
      expect(adSlotSchedule.virtualItemCount(17), 19);

      adSlotSchedule.reset();
      expect(adSlotSchedule.virtualItemCount(17), 17);
      expect(adSlotSchedule.isAdAtVirtualIndex(5), false);
    });
  });
}
