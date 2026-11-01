// 저장소 저장하는 Key 값
enum StorageKeys {
  loginPlatform('loginPlatforms'),
  // SharedPreferences: 홈 팝업 "다시 보지 않기" 누른 팝업 id 목록 (StringList)
  dismissedHomePopupIds('dismissedHomePopupIds'),
  // SharedPreferences: 홈 피드 최근 본 물품 id 목록 (StringList, 오래된 순, 회원별 키 '{key}_{memberId}') (#966)
  homeFeedRecentlySeenItemIds('homeFeedRecentlySeenItemIds');

  final String key;
  const StorageKeys(this.key);
}
