/// 거래 상태 태그 ENUM
enum TradeStatus {
  pending(label: '대기', serverName: 'PENDING'),
  traded(label: '거래 완료', serverName: 'TRADED'),
  canceled(label: '취소', serverName: 'CANCELED'),
  chatting(label: '채팅 중', serverName: 'CHATTING');

  final String label;
  final String serverName;

  const TradeStatus({required this.label, required this.serverName});

  static TradeStatus fromServerName(String name) {
    return TradeStatus.values.firstWhere(
      (e) => e.serverName == name,
      orElse: () =>
          throw ArgumentError('No ItemTradeOption with serverName $name'),
    );
  }
}
