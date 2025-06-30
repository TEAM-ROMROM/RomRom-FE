enum ItemTradeOption {
  extraCharge('추가금'),
  directOnly('직거래만'),
  deliveryOnly('택배거래만');

  final String description;
  
  const ItemTradeOption(this.description);
} 