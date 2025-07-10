/// 물품의 사용 상태
enum ItemCondition {
  newItem(name: '미개봉', serverName: 'SEALED'),
  lightlyUsed(name: '사용감 적음', serverName: 'SLIGHTLY_USED'),
  moderatelyUsed(name: '사용감 적당함', serverName: 'MODERATELY_USED'),
  heavilyUsed(name: '사용감 많음', serverName: 'HEAVILY_USED');

  final String name;
  final String serverName;

  const ItemCondition({required this.name, required this.serverName});
}
