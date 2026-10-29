/// 물품의 사용 상태
enum ItemCondition {
  sealed(label: '미개봉', serverName: 'SEALED'),
  slightlyUsed(label: '사용감 적음', serverName: 'SLIGHTLY_USED'),
  moderatelyUsed(label: '사용감 적당함', serverName: 'MODERATELY_USED'),
  heavilyUsed(label: '사용감 많음', serverName: 'HEAVILY_USED');

  final String label;
  final String serverName;

  const ItemCondition({required this.label, required this.serverName});

  /// 서버 이름 > 물품 상태 (모르는 값·null > null)
  static ItemCondition? fromServerName(String? serverName) {
    return ItemCondition.values.where((e) => e.serverName == serverName).firstOrNull;
  }
}
