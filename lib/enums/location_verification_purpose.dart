/// 동네 인증이 필요한 기능 4개 > 안내 모달 첫 줄
enum LocationVerificationPurpose {
  itemRegistration('물품을 등록하려면'),
  tradeRequest('교환을 요청하려면'),
  chatStart('채팅을 시작하려면'),
  searchRangeChange('탐색 범위를 바꾸려면');

  final String actionPhrase;

  const LocationVerificationPurpose(this.actionPhrase);
}
