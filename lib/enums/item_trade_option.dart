enum ItemTradeOption {
  extraCharge(name: '추가금', serverName: 'EXTRA_CHARGE'),
  directOnly(name: '직거래', serverName: 'DIRECT_ONLY'),
  deliveryOnly(name: '택배거래', serverName: 'DELIVERY_ONLY');

  final String name;
  final String serverName;

  const ItemTradeOption({required this.name, required this.serverName});

  static ItemTradeOption fromServerName(String name) {
    return ItemTradeOption.values.firstWhere(
      (e) => e.serverName == name,
      orElse: () =>
          throw ArgumentError('No ItemTradeOption with serverName $name'),
    );
  }
}
