enum ItemTradeOption {
  EXTRA_CHARGE('추가금'),
  DIRECT_ONLY('직거래만'),
  DELIVERY_ONLY('택배거래만');

  final String description;
  
  const ItemTradeOption(this.description);
} 