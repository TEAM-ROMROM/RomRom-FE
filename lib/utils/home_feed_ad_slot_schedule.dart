// 홈 피드 광고 슬롯 배치: 가상 index(피드 + 광고) <-> 피드 index 변환
import 'dart:math';

/// 홈 피드 광고 배치: 첫 5개 광고 없음 > 이후 8~11개 간격 무작위, 피드 길이 늘 때만 뒤에 추가
class HomeFeedAdSlotSchedule {
  // 광고 없이 보여 줄 첫 피드 개수
  static const int adFreeFeedCount = 5;
  // 광고 사이 피드 개수 범위 (양 끝 포함)
  static const int minimumAdInterval = 8;
  static const int maximumAdInterval = 11;

  HomeFeedAdSlotSchedule({Random? random}) : _random = random ?? Random();

  final Random _random;
  final Set<int> _adVirtualIndices = {};
  // 피드 index 계산용 오름차순 사본 (추가 순서 = 오름차순)
  final List<int> _adVirtualIndicesSorted = [];
  int _nextAdAfterFeedIndex = adFreeFeedCount;

  /// 피드 길이 > 광고 포함 전체 페이지 수
  int virtualItemCount(int feedLength) => feedLength + _adVirtualIndices.length;

  bool isAdAtVirtualIndex(int virtualIndex) => _adVirtualIndices.contains(virtualIndex);

  /// 가상 index > 피드 index (앞에 놓인 광고 수만큼 차감)
  int feedIndexAtVirtualIndex(int virtualIndex) {
    int adsBefore = 0;
    for (final adVirtualIndex in _adVirtualIndicesSorted) {
      if (adVirtualIndex > virtualIndex) break;
      adsBefore++;
    }
    return virtualIndex - adsBefore;
  }

  /// 피드 통째 교체 시 배치 초기화
  void reset() {
    _adVirtualIndices.clear();
    _adVirtualIndicesSorted.clear();
    _nextAdAfterFeedIndex = adFreeFeedCount;
  }

  /// 늘어난 피드 길이까지 광고 자리 추가 (기존 자리 유지)
  void scheduleAdsForFeedLength(int feedLength) {
    while (_nextAdAfterFeedIndex < feedLength) {
      final virtualIndex = _nextAdAfterFeedIndex + _adVirtualIndices.length;
      _adVirtualIndices.add(virtualIndex);
      _adVirtualIndicesSorted.add(virtualIndex);
      _nextAdAfterFeedIndex += minimumAdInterval + _random.nextInt(maximumAdInterval - minimumAdInterval + 1);
    }
  }
}
