/// 거래 유형
enum TransactionType {
  additionalCharge(name: '추가금'),
  directDeal(name: '직거래'),
  delivery(name: '택배');

  final String name;

  const TransactionType({required this.name});
}
