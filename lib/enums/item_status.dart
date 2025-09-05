/// 물품 거래 상태 enum (프론트 ↔︎ 백엔드 매핑)
///
/// id    : 내부 식별용 코드
/// name  : 클라이언트 표시용 한글 이름  
/// serverName : 백엔드 enum 이름
///
/// 백엔드 enum 참고:
/// AVAILABLE (판매중), EXCHANGED (거래완료)
///
/// 사용 예시
///   ItemStatus.values.forEach((status) => print(status.name));
///   final serverValue = selectedStatus.serverName; // API 전송용
enum ItemStatus {
  available(id: 1, name: '판매중', serverName: 'AVAILABLE'),
  exchanged(id: 2, name: '거래완료', serverName: 'EXCHANGED');

  final int id;
  final String name;
  final String serverName;

  const ItemStatus({required this.id, required this.name, required this.serverName});

  /// serverName으로부터 ItemStatus를 찾는 헬퍼 메서드
  static ItemStatus? fromServerName(String serverName) {
    try {
      return ItemStatus.values.firstWhere((status) => status.serverName == serverName);
    } catch (e) {
      return null;
    }
  }
}