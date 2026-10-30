// 저장소 저장하는 Key 값
enum StorageKeys {
  loginPlatform('loginPlatforms'),
  // SharedPreferences: 홈 팝업 "다시 보지 않기" 누른 팝업 id 목록 (StringList)
  dismissedHomePopupIds('dismissedHomePopupIds');

  final String key;
  const StorageKeys(this.key);
}
