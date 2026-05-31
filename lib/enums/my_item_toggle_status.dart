/// 내 물건 탭 토글 상태 enum
enum MyItemToggleStatus {
  all(id: 0, label: '전체', serverName: ''),
  selling(id: 1, label: '등록 물건', serverName: 'AVAILABLE'),
  completed(id: 2, label: '교환 완료', serverName: 'EXCHANGED');

  final int id;
  final String label;
  final String serverName;

  const MyItemToggleStatus({required this.id, required this.label, required this.serverName});

  static MyItemToggleStatus? fromServerName(String serverName) {
    try {
      return MyItemToggleStatus.values.firstWhere((s) => s.serverName == serverName);
    } catch (_) {
      return null;
    }
  }
}
