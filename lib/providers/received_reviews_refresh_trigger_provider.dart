import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 받은 후기 재조회 신호 (후기 도착 푸시 > 열린 내 프로필 후기 목록 재조회, #1007)
/// 값은 요청 횟수: 바뀔 때마다 구독 중인 후기 영역이 다시 조회 (소비 불필요)
class ReceivedReviewsRefreshTriggerNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void requestRefresh() => state = state + 1;
}

final receivedReviewsRefreshTriggerProvider = NotifierProvider<ReceivedReviewsRefreshTriggerNotifier, int>(
  ReceivedReviewsRefreshTriggerNotifier.new,
);
