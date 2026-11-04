/// 회원 탈퇴 사유 6개 (서버 MemberWithdrawalReason) (#1008)
enum MemberWithdrawalReason {
  rarelyUsed(label: '자주 사용하지 않아요', serverName: 'RARELY_USED'),
  noWantedItems(label: '원하는 물건이 없어요', serverName: 'NO_WANTED_ITEMS'),
  unsatisfyingTrade(label: '교환 경험이 만족스럽지 않았어요', serverName: 'UNSATISFYING_TRADE'),
  inconvenientService(label: '앱 사용이 불편해요', serverName: 'INCONVENIENT_SERVICE'),
  privacyConcern(label: '개인정보가 걱정돼요', serverName: 'PRIVACY_CONCERN'),
  other(label: '기타', serverName: 'OTHER');

  final String label;
  final String serverName;

  const MemberWithdrawalReason({required this.label, required this.serverName});
}
