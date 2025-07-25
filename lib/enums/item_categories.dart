/// 카테고리(대분류) `id` : id `name` : 카테고리 이름
enum ItemCategories {
  womensClothing(id: 1, name: '여성의류', serverName: 'WOMEN_CLOTHING'),
  mensClothing(id: 2, name: '남성의류', serverName: 'MEN_CLOTHING'),
  shoes(id: 3, name: '신발', serverName: 'SHOES'),
  bagsWallets(id: 4, name: '가방/지갑', serverName: 'BAGS_WALLETS'),
  watches(id: 5, name: '시계', serverName: 'WATCHES'),
  jewelry(id: 6, name: '주얼리', serverName: 'JEWELRY'),
  fashionAccessories(id: 7, name: '패션 액세서리', serverName: 'FASHION_ACCESSORIES'),
  electronics(
      id: 8, name: '전자기기/스마트기기', serverName: 'ELECTRONICS_SMART_DEVICES'),
  largeAppliances(id: 9, name: '대형가전', serverName: 'LARGE_APPLIANCES'),
  smallAppliances(id: 10, name: '소형가전', serverName: 'SMALL_APPLIANCES'),
  sportsLeisure(id: 11, name: '스포츠/레저', serverName: 'SPORTS_LEISURE'),
  vehicles(id: 12, name: '차량/오토바이', serverName: 'VEHICLES_MOTORCYCLES'),
  starGoods(id: 13, name: '스타굿즈', serverName: 'STAR_GOODS'),
  kidult(id: 14, name: '키덜트', serverName: 'KIDULT'),
  artCollection(id: 15, name: '예술/희귀/수집품', serverName: 'ART_RARE_COLLECTIBLES'),
  musicInstruments(id: 16, name: '음반/악기', serverName: 'MUSIC_INSTRUMENTS'),
  booksTicketsStationery(
      id: 17, name: '도서/티켓/문구', serverName: 'BOOKS_TICKETS_STATIONERY'),
  beauty(id: 18, name: '뷰티/미용', serverName: 'BEAUTY'),
  furnitureInterior(id: 19, name: '가구/인테리어', serverName: 'FURNITURE_INTERIOR'),
  homeKitchen(id: 20, name: '생활/주방용품', serverName: 'LIFE_KITCHEN'),
  toolsIndustrial(id: 21, name: '공구/산업용품', serverName: 'TOOLS_INDUSTRIAL'),
  food(id: 22, name: '식품', serverName: 'FOOD'),
  babyProducts(id: 23, name: '유아용품', serverName: 'BABY'),
  petSupplies(id: 24, name: '반려동물용품', serverName: 'PET_PRODUCTS'),
  etc(id: 25, name: '기타', serverName: 'OTHER'),
  talentServiceExchange(id: 26, name: '재능 (서비스나 기술 교환)', serverName: 'SKILL');

  final int id;
  final String name;
  final String serverName;

  const ItemCategories(
      {required this.id, required this.name, required this.serverName});
}
