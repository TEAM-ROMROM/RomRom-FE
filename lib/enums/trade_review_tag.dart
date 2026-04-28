/// 거래 후기 태그 enum
enum TradeReviewTag {
  fastResponse(label: '답장이 빨라요', serverName: 'FAST_RESPONSE'),
  goodItemCondition(label: '물건 상태가 좋아요', serverName: 'GOOD_ITEM_CONDITION'),
  matchesPhoto(label: '사진과 같아요', serverName: 'MATCHES_PHOTO'),
  punctual(label: '약속을 잘 지켜요', serverName: 'PUNCTUAL'),
  kind(label: '친절해요', serverName: 'KIND');

  final String label;
  final String serverName;

  const TradeReviewTag({required this.label, required this.serverName});
}
