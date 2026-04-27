/// 카테고리(대분류) `id` : id `name` : 카테고리 이름
enum ItemCategories {
  womensClothing(
    id: 1,
    label: '여성의류',
    serverName: 'WOMEN_CLOTHING',
    iconPath: 'assets/images/categories/womens-clothing.svg',
  ),
  mensClothing(
    id: 2,
    label: '남성의류',
    serverName: 'MEN_CLOTHING',
    iconPath: 'assets/images/categories/mens-clothing.svg',
  ),
  shoes(id: 3, label: '신발', serverName: 'SHOES', iconPath: 'assets/images/categories/shoes.svg'),
  bagsWallets(id: 4, label: '가방/지갑', serverName: 'BAGS_WALLETS', iconPath: 'assets/images/categories/bags-wallets.svg'),
  fashionAccessories(
    id: 7,
    label: '액세서리',
    serverName: 'FASHION_ACCESSORIES',
    iconPath: 'assets/images/categories/fashion-accessories.svg',
  ),
  electronics(
    id: 8,
    label: '전자기기',
    serverName: 'ELECTRONICS_SMART_DEVICES',
    iconPath: 'assets/images/categories/electronics.svg',
  ),
  largeAppliances(
    id: 9,
    label: '대형가전',
    serverName: 'LARGE_APPLIANCES',
    iconPath: 'assets/images/categories/large-appliances.svg',
  ),
  smallAppliances(
    id: 10,
    label: '소형가전',
    serverName: 'SMALL_APPLIANCES',
    iconPath: 'assets/images/categories/small-appliances.svg',
  ),
  sportsLeisure(
    id: 11,
    label: '스포츠/레저',
    serverName: 'SPORTS_LEISURE',
    iconPath: 'assets/images/categories/sports-leisure.svg',
  ),
  vehicles(
    id: 12,
    label: '차량/오토바이',
    serverName: 'VEHICLES_MOTORCYCLES',
    iconPath: 'assets/images/categories/vehicles.svg',
  ),
  starGoods(id: 13, label: '굿즈', serverName: 'STAR_GOODS', iconPath: 'assets/images/categories/star-goods.svg'),
  artCollection(
    id: 15,
    label: '예술/수집품',
    serverName: 'ART_RARE_COLLECTIBLES',
    iconPath: 'assets/images/categories/art-collection.svg',
  ),
  musicInstruments(
    id: 16,
    label: '음반/악기',
    serverName: 'MUSIC_INSTRUMENTS',
    iconPath: 'assets/images/categories/music-instruments.svg',
  ),
  booksTicketsStationery(
    id: 17,
    label: '도서/문구',
    serverName: 'BOOKS_TICKETS_STATIONERY',
    iconPath: 'assets/images/categories/books-tickets-stationery.svg',
  ),
  beauty(id: 18, label: '뷰티/미용', serverName: 'BEAUTY', iconPath: 'assets/images/categories/beauty.svg'),
  furnitureInterior(
    id: 19,
    label: '가구/인테리어',
    serverName: 'FURNITURE_INTERIOR',
    iconPath: 'assets/images/categories/furniture-interior.svg',
  ),
  homeKitchen(
    id: 20,
    label: '생활/주방용품',
    serverName: 'LIFE_KITCHEN',
    iconPath: 'assets/images/categories/home-kitchen.svg',
  ),
  toolsIndustrial(
    id: 21,
    label: '공구/산업용품',
    serverName: 'TOOLS_INDUSTRIAL',
    iconPath: 'assets/images/categories/tools-industrial.svg',
  ),
  babyProducts(id: 23, label: '유아용품', serverName: 'BABY', iconPath: 'assets/images/categories/baby-products.svg'),
  petSupplies(
    id: 24,
    label: '반려동물용품',
    serverName: 'PET_PRODUCTS',
    iconPath: 'assets/images/categories/pet-supplies.svg',
  ),
  etc(id: 25, label: '기타', serverName: 'OTHER', iconPath: 'assets/images/categories/etc.svg'),
  talentServiceExchange(
    id: 26,
    label: '재능/서비스',
    serverName: 'SKILL',
    iconPath: 'assets/images/categories/talent-service-exchange.svg',
  );

  final int id;
  final String label;
  final String serverName;
  final String iconPath;

  const ItemCategories({required this.id, required this.label, required this.serverName, required this.iconPath});

  static ItemCategories fromServerName(String serverName) {
    return ItemCategories.values.firstWhere(
      (e) => e.serverName == serverName,
      orElse: () => throw ArgumentError('Invalid serverName: $serverName'),
    );
  }
}
