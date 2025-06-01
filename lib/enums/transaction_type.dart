/// 거래 유형
enum TransactionType {
  directDeal(name: '직거래'),
  delivery(name: '택배'),
  additionalCharge(name: '추가금');

  final String name;

  const TransactionType({required this.name});
}