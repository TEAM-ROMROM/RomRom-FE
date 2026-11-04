// 저장소 저장하는 Key 값
enum StorageKeys {
  loginPlatform('loginPlatforms'),
  // SharedPreferences: 홈 팝업 "다시 보지 않기" 누른 팝업 id 목록 (StringList)
  dismissedHomePopupIds('dismissedHomePopupIds'),
  // SharedPreferences: 홈 피드 최근 본 물품 id 목록 (StringList, 오래된 순, 회원별 키 '{key}_{memberId}') (#966)
  homeFeedRecentlySeenItemIds('homeFeedRecentlySeenItemIds'),
  // SharedPreferences: 좌표 > 주소 캐시 (JSON, 오래된 순 [키, 주소] 목록, 최대 500개) (#975)
  addressLookupCache('addressLookupCacheV1'),
  // SharedPreferences: GPS 동네 인증 기록 (JSON {memberId, verifiedAt, latitude, longitude}, 로그아웃 시 삭제) (#986)
  locationVerificationRecord('locationVerificationRecord'),
  // SharedPreferences: 알림 권한 안내 노출 여부 (bool, 설치당 1회, 로그아웃·탈퇴에도 유지) (#986)
  notificationPermissionPromptAsked('notificationPermissionPromptAsked');

  final String key;
  const StorageKeys(this.key);
}
