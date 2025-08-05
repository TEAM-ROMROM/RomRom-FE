enum ItemTradeOption {
  extraCharge(name: '추가금', serverName: 'EXTRA_CHARGE'),
  directOnly(name: '직거래만', serverName: 'DIRECT_ONLY'),
  deliveryOnly(name: '택배거래만', serverName: 'DELIVERY_ONLY');

  final String name;
  final String serverName;

  const ItemTradeOption({required this.name, required this.serverName});
}
