enum RequestSortType {
  latest(label: '최신순', serverName: 'CREATED_DATE'),
  priceHigh(label: '가격 높은순', serverName: 'PRICE_HIGH'),
  priceLow(label: '가격 낮은순', serverName: 'PRICE_LOW'),
  aiRecommend(label: 'AI 추천순', serverName: 'RECOMMENDED');

  final String label;
  final String serverName;

  const RequestSortType({required this.label, required this.serverName});
}
