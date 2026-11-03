// 홈 피드 목록 축소(신고·차단 제외) 후 보던 위치 계산

/// 축소 후 피드 index: 보던 물품 앞에서 남은 물품 수 (보던 물품이 남았으면 그 물품, 빠졌으면 다음 남은 물품)
/// 같은 객체 기준 비교 (provider 필터는 남은 항목 객체를 그대로 유지)
int resolveFeedIndexAfterRemoval<T extends Object>({
  required List<T> previousItems,
  required List<T> remainingItems,
  required int previousFeedIndex,
}) {
  final remainingItemSet = Set<T>.identity()..addAll(remainingItems);
  return previousItems.take(previousFeedIndex).where(remainingItemSet.contains).length;
}
