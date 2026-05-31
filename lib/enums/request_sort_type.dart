enum RequestSortType {
  // BE TradeRequestSortField(enum name) + Sort.Direction(ASC/DESC) 매핑
  // 가격 높은/낮은순은 동일 sortField(PRICE)에 방향만 다름. AI 추천은 방향 무시됨.
  latest(label: '최신순', serverSortField: 'CREATED_DATE', serverDirection: 'DESC'),
  priceHigh(label: '가격 높은순', serverSortField: 'PRICE', serverDirection: 'DESC'),
  priceLow(label: '가격 낮은순', serverSortField: 'PRICE', serverDirection: 'ASC'),
  aiRecommend(label: 'AI 추천순', serverSortField: 'AI_RECOMMENDED', serverDirection: 'DESC');

  final String label;
  final String serverSortField; // BE TradeRequestSortField enum name (CREATED_DATE/PRICE/AI_RECOMMENDED)
  final String serverDirection; // BE Sort.Direction (ASC/DESC), AI_RECOMMENDED 정렬에서는 무시됨

  const RequestSortType({required this.label, required this.serverSortField, required this.serverDirection});
}
