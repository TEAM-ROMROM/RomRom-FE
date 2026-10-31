enum ItemTradeOption {
  additionalPrice(label: '추가금', serverName: 'EXTRA_CHARGE'),
  directTradeOnly(label: '직거래', serverName: 'DIRECT_ONLY'),
  deliveryOnly(label: '택배', serverName: 'DELIVERY_ONLY');

  final String label;
  final String serverName;

  const ItemTradeOption({required this.label, required this.serverName});

  /// 서버 이름 > 거래 방식 (모르는 값·null > null)
  static ItemTradeOption? fromServerName(String? name) {
    return ItemTradeOption.values.where((e) => e.serverName == name).firstOrNull;
  }

  /// 서버 이름 목록 > 거래 방식 목록 (모르는 값 제외, 순서 유지, null > 빈 목록)
  static List<ItemTradeOption> fromServerNamesSkippingUnknown(Iterable<String>? serverNames) {
    if (serverNames == null) return const [];
    return [
      for (final serverName in serverNames)
        ...ItemTradeOption.values.where((option) => option.serverName == serverName),
    ];
  }
}
