/// 거래 상태 태그 ENUM
enum TradeStatus {
  pending(label: '대기', serverName: 'PENDING'),
  traded(label: '교환 완료', serverName: 'TRADED'),
  canceled(label: '취소', serverName: 'CANCELED'),
  chatting(label: '채팅 중', serverName: 'CHATTING'),
  // 보낸 요청 목록에서만 내려옴 (includeRejected=true, #1005)
  rejected(label: '거절됨', serverName: 'REJECTED');

  final String label;
  final String serverName;

  const TradeStatus({required this.label, required this.serverName});

  /// 서버 이름 > 거래 상태 (모르는 값·null > null)
  static TradeStatus? fromServerName(String? name) {
    return TradeStatus.values.where((e) => e.serverName == name).firstOrNull;
  }
}
