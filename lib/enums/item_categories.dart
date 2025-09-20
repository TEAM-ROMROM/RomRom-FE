/// 카테고리(대분류) `id` : id `name` : 카테고리 이름
enum ItemCategories {
  womensClothing(id: 1, label: '여성의류', serverName: 'WOMEN_CLOTHING'),
  mensClothing(id: 2, label: '남성의류', serverName: 'MEN_CLOTHING'),
  shoes(id: 3, label: '신발', serverName: 'SHOES'),
  bagsWallets(id: 4, label: '가방/지갑', serverName: 'BAGS_WALLETS'),
  watches(id: 5, label: '시계', serverName: 'WATCHES'),
  jewelry(id: 6, label: '주얼리', serverName: 'JEWELRY'),
  fashionAccessories(id: 7, label: '패션 액세서리', serverName: 'FASHION_ACCESSORIES'),
  electronics(
      id: 8, label: '전자기기/스마트기기', serverName: 'ELECTRONICS_SMART_DEVICES'),
  largeAppliances(id: 9, label: '대형가전', serverName: 'LARGE_APPLIANCES'),
  smallAppliances(id: 10, label: '소형가전', serverName: 'SMALL_APPLIANCES'),
  sportsLeisure(id: 11, label: '스포츠/레저', serverName: 'SPORTS_LEISURE'),
  vehicles(id: 12, label: '차량/오토바이', serverName: 'VEHICLES_MOTORCYCLES'),
  starGoods(id: 13, label: '스타굿즈', serverName: 'STAR_GOODS'),
  kidult(id: 14, label: '키덜트', serverName: 'KIDULT'),
  artCollection(id: 15, label: '예술/희귀/수집품', serverName: 'ART_RARE_COLLECTIBLES'),
  musicInstruments(id: 16, label: '음반/악기', serverName: 'MUSIC_INSTRUMENTS'),
  booksTicketsStationery(
      id: 17, label: '도서/티켓/문구', serverName: 'BOOKS_TICKETS_STATIONERY'),
  beauty(id: 18, label: '뷰티/미용', serverName: 'BEAUTY'),
  furnitureInterior(id: 19, label: '가구/인테리어', serverName: 'FURNITURE_INTERIOR'),
  homeKitchen(id: 20, label: '생활/주방용품', serverName: 'LIFE_KITCHEN'),
  toolsIndustrial(id: 21, label: '공구/산업용품', serverName: 'TOOLS_INDUSTRIAL'),
  food(id: 22, label: '식품', serverName: 'FOOD'),
  babyProducts(id: 23, label: '유아용품', serverName: 'BABY'),
  petSupplies(id: 24, label: '반려동물용품', serverName: 'PET_PRODUCTS'),
  etc(id: 25, label: '기타', serverName: 'OTHER'),
  talentServiceExchange(id: 26, label: '재능 (서비스나 기술 교환)', serverName: 'SKILL');

  final int id;
  final String label;
  final String serverName;

  const ItemCategories(
      {required this.id, required this.label, required this.serverName});

  static ItemCategories fromServerName(String serverName) {
    return ItemCategories.values.firstWhere(
      (e) => e.serverName == serverName,
      orElse: () => throw ArgumentError('Invalid serverName: $serverName'),
    );
  }
}
