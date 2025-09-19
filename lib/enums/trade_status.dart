/// 거래 상태 태그 위젯
library;

enum TradeStatus {
  pending(name: '대기', serverName: 'PENDING'),
  accepted(name: '승인', serverName: 'ACCEPTED'),
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
