/// 알림 타입
enum NotificationType {
  tradeRequestReceived(label: '교환 요청', serverName: 'TRADE_REQUEST_RECEIVED'),
  chatMessageReceived(label: '채팅', serverName: 'CHAT_MESSAGE_RECEIVED'),
  itemLiked(label: '좋아요', serverName: 'ITEM_LIKED'),
  announcement(label: '공지사항', serverName: 'ANNOUNCEMENT'),
  itemDeletedByAdmin(label: '게시글 삭제', serverName: 'ITEM_DELETED_BY_ADMIN'),

  // 거래 소식 확장 (#1007, BE #861)
  tradeRequestAccepted(label: '교환 수락', serverName: 'TRADE_REQUEST_ACCEPTED'),
  tradeRequestRejected(label: '교환 거절', serverName: 'TRADE_REQUEST_REJECTED'),
  tradeCompleted(label: '교환 완료', serverName: 'TRADE_COMPLETED'),
  tradeReviewReceived(label: '받은 후기', serverName: 'TRADE_REVIEW_RECEIVED'),

  // 등록 키워드가 들어간 새 물품 (#1020, BE #873)
  keywordItemRegistered(label: '키워드 알림', serverName: 'KEYWORD_ITEM_REGISTERED'),

  // 관리자 광고성 푸시 (마케팅 수신 동의자 대상, #1021)
  marketing(label: '이벤트·혜택', serverName: 'MARKETING'),

  // 모르는 서버 값 폴백 (서버 이름 조회 대상 아님, 끌 수 있는 설정 없음)
  unknown(label: '알림', serverName: '');

  final String label;
  final String serverName;

  const NotificationType({required this.label, required this.serverName});

  /// 알림 카테고리별 SVG 아이콘 경로
  String get svgAssetPath {
    switch (this) {
      case NotificationType.tradeRequestReceived:
      case NotificationType.tradeRequestAccepted:
      case NotificationType.tradeRequestRejected:
      case NotificationType.tradeCompleted:
        return 'assets/images/notificationExchangeYellowCircle.svg';
      case NotificationType.chatMessageReceived:
        return 'assets/images/notificationChat.svg';
      case NotificationType.itemLiked:
      case NotificationType.tradeReviewReceived:
        return 'assets/images/notificationLike.svg';
      case NotificationType.announcement:
      case NotificationType.itemDeletedByAdmin:
      case NotificationType.keywordItemRegistered:
      case NotificationType.marketing:
      case NotificationType.unknown:
        return 'assets/images/notificationAnnouncement.svg';
    }
  }

  /// 서버 이름 > 알림 타입 (모르는 값·null > null, unknown은 조회 대상 아님)
  static NotificationType? fromServerName(String? name) {
    return NotificationType.values
        .where((type) => type != NotificationType.unknown && type.serverName == name)
        .firstOrNull;
  }
}
