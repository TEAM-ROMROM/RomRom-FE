// 목록 광고 배치: 콘텐츠 index <-> 광고 포함 목록 index (광고 칸은 고정 위치 > 목록이 바뀌어도 칸 위치 유지)

/// 목록 광고 배치 규칙: 콘텐츠 [firstAdAfterContentCount]개 뒤 첫 광고 > 이후 [adIntervalContentCount]개마다 (null = 1개만)
/// 광고는 콘텐츠가 그 개수 이상일 때만 (예: 8개마다 > 8개째 뒤, 16개째 뒤)
class ListAdPlacement {
  const ListAdPlacement({required this.firstAdAfterContentCount, this.adIntervalContentCount})
    : assert(firstAdAfterContentCount > 0),
      assert(adIntervalContentCount == null || adIntervalContentCount > 0);

  // 채팅방 목록: 3번째 방 뒤 1개 (방 3개 이상일 때만)
  static const ListAdPlacement chatRoomList = ListAdPlacement(firstAdAfterContentCount: 3);
  // 물품 목록(좋아요·내 물품): 8개마다 1개
  static const ListAdPlacement itemList = ListAdPlacement(firstAdAfterContentCount: 8, adIntervalContentCount: 8);

  final int firstAdAfterContentCount;
  final int? adIntervalContentCount;

  /// 콘텐츠 수 > 광고 수
  int adCount(int contentCount) {
    if (contentCount < firstAdAfterContentCount) return 0;
    final interval = adIntervalContentCount;
    if (interval == null) return 1;
    return 1 + (contentCount - firstAdAfterContentCount) ~/ interval;
  }

  /// 콘텐츠 수 > 광고 포함 목록 길이
  int listItemCount(int contentCount) => contentCount + adCount(contentCount);

  /// 목록 index가 광고 칸인지 (목록 범위 밖이면 false)
  bool isAdAtListIndex(int listIndex, int contentCount) {
    final offsetFromFirstAd = listIndex - firstAdAfterContentCount;
    if (offsetFromFirstAd < 0) return false;
    final interval = adIntervalContentCount;
    if (interval == null) return offsetFromFirstAd == 0 && adCount(contentCount) == 1;
    final adStride = interval + 1;
    return offsetFromFirstAd % adStride == 0 && offsetFromFirstAd ~/ adStride < adCount(contentCount);
  }

  /// 목록 index(광고 칸 아님) > 콘텐츠 index (앞에 놓인 광고 수만큼 차감)
  int contentIndexAtListIndex(int listIndex) => listIndex - _adCountBeforeListIndex(listIndex);

  /// 콘텐츠 index > 목록 index (앞에 놓인 광고 수만큼 더함)
  int listIndexAtContentIndex(int contentIndex) {
    if (contentIndex < firstAdAfterContentCount) return contentIndex;
    final interval = adIntervalContentCount;
    if (interval == null) return contentIndex + 1;
    return contentIndex + 1 + (contentIndex - firstAdAfterContentCount) ~/ interval;
  }

  int _adCountBeforeListIndex(int listIndex) {
    final offsetFromFirstAd = listIndex - firstAdAfterContentCount;
    if (offsetFromFirstAd <= 0) return 0;
    final interval = adIntervalContentCount;
    if (interval == null) return 1;
    // 광고 칸 목록 index: first + k * (interval + 1) > 앞에 놓인 개수 = 올림(offset / stride)
    final adStride = interval + 1;
    return (offsetFromFirstAd + adStride - 1) ~/ adStride;
  }
}
