/// 물품의 사용 상태
enum ItemCondition {
  newItem(name: '미개봉'),
  lightlyUsed(name: '사용감 적음'),
  moderatelyUsed(name: '사용감 적당함'),
  heavilyUsed(name: '사용감 많음');

  final String name;

  const ItemCondition({required this.name});
}