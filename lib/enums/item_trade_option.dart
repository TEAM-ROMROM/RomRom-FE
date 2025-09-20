enum ItemTradeOption {
  extraCharge(label: '추가금', serverName: 'EXTRA_CHARGE'),
  directOnly(label: '직거래', serverName: 'DIRECT_ONLY'),
  deliveryOnly(label: '택배', serverName: 'DELIVERY_ONLY');

  final String label;
  final String serverName;

  const ItemTradeOption({required this.label, required this.serverName});

  static ItemTradeOption fromServerName(String name) {
    return ItemTradeOption.values.firstWhere(
      (e) => e.serverName == name,
      orElse: () =>
          throw ArgumentError('No ItemTradeOption with serverName $name'),
    );
  }
}
