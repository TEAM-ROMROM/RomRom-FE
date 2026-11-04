/// 물품 검색 정렬 기준 4개 (서버 ItemSearchSortField, 홈 피드 ItemSortField와 별도) (#1008)
/// 거리순: 회원 위치 기준, 위치 미등록이면 서버가 최신순으로 정렬
enum ItemSearchSortField {
  latest(label: '최신순', serverName: 'LATEST'),
  distance(label: '거리순', serverName: 'DISTANCE'),
  priceAscending(label: '낮은 가격순', serverName: 'PRICE_ASC'),
  priceDescending(label: '높은 가격순', serverName: 'PRICE_DESC');

  final String label;
  final String serverName;

  const ItemSearchSortField({required this.label, required this.serverName});
}
