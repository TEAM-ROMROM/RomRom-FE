/// 카테고리(대분류) `id` : id `name` : 카테고리 이름
enum ItemCategories {
  womensClothing(id: 1, name: '여성의류'),
  mensClothing(id: 2, name: '남성의류'),
  shoes(id: 3, name: '신발'),
  bagsWallets(id: 4, name: '가방/지갑'),
  watches(id: 5, name: '시계'),
  jewelry(id: 6, name: '주얼리'),
  fashionAccessories(id: 7, name: '패션 액세서리'),
  electronics(id: 8, name: '전자기기/스마트기기'),
  largeAppliances(id: 9, name: '대형가전'),
  smallAppliances(id: 10, name: '소형가전'),
  sportsLeisure(id: 11, name: '스포츠/레저'),
  vehicles(id: 12, name: '차량/오토바이'),
  starGoods(id: 13, name: '스타굿즈'),
  kidult(id: 14, name: '키덜트'),
  artCollection(id: 15, name: '예술/희귀/수집품'),
  musicInstruments(id: 16, name: '음반/악기'),
  booksTicketsStationery(id: 17, name: '도서/티켓/문구'),
  beauty(id: 18, name: '뷰티/미용'),
  furnitureInterior(id: 19, name: '가구/인테리어'),
  homeKitchen(id: 20, name: '생활/주방용품'),
  toolsIndustrial(id: 21, name: '공구/산업용품'),
  food(id: 22, name: '식품'),
  babyProducts(id: 23, name: '유아용품'),
  petSupplies(id: 24, name: '반려동물용품'),
  etc(id: 25, name: '기타'),
  talentServiceExchange(id: 26, name: '재능 (서비스나 기술 교환)');

  final int id;
  final String name;

  const ItemCategories({required this.id, required this.name});
}
