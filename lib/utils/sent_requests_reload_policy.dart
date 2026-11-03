import 'package:flutter/foundation.dart';

/// 보낸 요청 재조회 판단: 마지막 전체 조회 카드 목록·시작 시각 기록 > 카드 로드·백그라운드 재조회 필요 여부
/// 보낸 요청은 카드 수만큼 호출 > 같은 카드 목록 반복 조회와 짧은 간격 연속 조회를 줄임
class SentRequestsReloadPolicy {
  SentRequestsReloadPolicy({required this.minimumBackgroundReloadInterval});

  /// 백그라운드 재조회 최소 간격 (마지막 전체 조회 시작 기준)
  final Duration minimumBackgroundReloadInterval;

  List<String>? _lastLoadedItemIds;
  DateTime? _lastLoadStartedAt;

  /// 전체 카드 조회 시작 기록 (실패 카드만 재조회는 기록 안 함)
  void recordFullLoad(List<String> itemIds, {required DateTime startedAt}) {
    _lastLoadedItemIds = itemIds;
    _lastLoadStartedAt = startedAt;
  }

  /// 카드 로드 때 보낸 요청 조회 여부 (강제 또는 마지막 전체 조회와 카드 목록 다름)
  bool shouldLoadForItems(List<String> itemIds, {required bool isForced}) =>
      isForced || !listEquals(_lastLoadedItemIds, itemIds);

  /// 탭 진입·앱 복귀 백그라운드 재조회 여부 (첫 전체 조회 전 > false, 최소 간격 지남 > true)
  bool shouldReloadInBackground(DateTime now) {
    final lastLoadStartedAt = _lastLoadStartedAt;
    if (lastLoadStartedAt == null) return false;
    return now.difference(lastLoadStartedAt) >= minimumBackgroundReloadInterval;
  }

  /// 기록 비움 (세션 전환)
  void reset() {
    _lastLoadedItemIds = null;
    _lastLoadStartedAt = null;
  }
}
