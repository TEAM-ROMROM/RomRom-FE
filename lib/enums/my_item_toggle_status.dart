/// 내 물건 탭 토글 상태 enum
enum MyItemToggleStatus {
  all(id: 0, label: '전체', serverName: ''),
  selling(id: 1, label: '등록 물품', serverName: 'AVAILABLE'),
  completed(id: 2, label: '교환 완료', serverName: 'EXCHANGED');

  final int id;
  final String label;
  final String serverName;

  const MyItemToggleStatus({required this.id, required this.label, required this.serverName});

  /// 서버 이름 > 내 물건 토글 상태 (모르는 값·null > null)
  static MyItemToggleStatus? fromServerName(String? serverName) {
    return MyItemToggleStatus.values.where((s) => s.serverName == serverName).firstOrNull;
  }
}
