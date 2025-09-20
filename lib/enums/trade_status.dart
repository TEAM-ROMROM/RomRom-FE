/// 거래 상태 태그 ENUM
enum TradeStatus {
  pending(name: '대기', serverName: 'PENDING'),
  traded(name: '거래 완료', serverName: 'TRADED'),
  canceled(name: '취소', serverName: 'CANCELED'),
  chatting(name: '채팅 중', serverName: 'CHATTING');

  final String name;
  final String serverName;

  const TradeStatus({required this.name, required this.serverName});

  static TradeStatus fromServerName(String name) {
    return TradeStatus.values.firstWhere(
      (e) => e.serverName == name,
      orElse: () =>
          throw ArgumentError('No ItemTradeOption with serverName $name'),
    );
  }
}
