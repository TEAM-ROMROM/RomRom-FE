/// 내 물건 탭 토글 상태 enum
enum MyItemToggleStatus {
  selling(id: 1, label: '판매 중', serverName: 'AVAILABLE'),
  completed(id: 2, label: '거래 완료', serverName: 'EXCHANGED');

  final int id;
  final String label;
  final String serverName;

  const MyItemToggleStatus({
    required this.id,
    required this.label,
    required this.serverName,
  });

  /// 서버 이름으로부터 enum 값으로 변환
  static MyItemToggleStatus? fromServerName(String serverName) {
    try {
      return MyItemToggleStatus.values
          .firstWhere((status) => status.serverName == serverName);
    } catch (e) {
      return null;
    }
  }
}
