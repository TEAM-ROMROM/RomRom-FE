/// 물품의 사용 상태
enum ItemCondition {
  newItem(label: '새상품', serverName: 'NEW'),
  good(label: '상태 좋음', serverName: 'GOOD'),
  fair(label: '보통', serverName: 'FAIR'),
  poor(label: '상태 나쁨', serverName: 'POOR');

  final String label;
  final String serverName;

  const ItemCondition({required this.label, required this.serverName});

  /// 서버 이름으로부터 enum 값으로 변환
  static ItemCondition fromServerName(String serverName) {
    return ItemCondition.values.firstWhere(
      (e) => e.serverName == serverName,
      orElse: () => throw ArgumentError('Invalid serverName: $serverName'),
    );
  }
}
