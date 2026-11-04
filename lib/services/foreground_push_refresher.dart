import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/notification_type.dart';

/// 갱신 대상 1건: 로그용 이름 + 재조회 함수
typedef ForegroundRefreshTarget = ({String name, Future<void> Function() reload});

/// 앱 사용 중 푸시 분배: 푸시 종류 판정, 알림 목록·미확인 개수·받은/보낸 요청·내 물품·채팅방·받은 후기 재조회
/// 종류별 갱신 대상 선택 > 병렬 실행 (하나가 실패해도 나머지 진행)
class ForegroundPushRefresher {
  final Future<void> Function() reloadNotificationList;
  final Future<void> Function() refreshNotificationUnreadCount;
  final Future<void> Function() reloadReceivedTradeRequests;
  final Future<void> Function() reloadMyItems;
  final Future<void> Function() reloadSentTradeRequests;
  final Future<void> Function() reloadChatRooms;
  final Future<void> Function() reloadReceivedReviews;

  ForegroundPushRefresher({
    required this.reloadNotificationList,
    required this.refreshNotificationUnreadCount,
    required this.reloadReceivedTradeRequests,
    required this.reloadMyItems,
    required this.reloadSentTradeRequests,
    required this.reloadChatRooms,
    required this.reloadReceivedReviews,
  });

  /// FCM data 페이로드 > 종류 판정 > 해당 갱신 실행 (예외는 밖으로 던지지 않음)
  Future<void> onForegroundPush(Map<String, dynamic> data) async {
    final rawNotificationType = data['notificationType'];
    final notificationType = NotificationType.fromServerName(
      rawNotificationType is String ? rawNotificationType : null,
    );

    await Future.wait([
      for (final target in _resolveRefreshTargets(notificationType)) _runSafely(target.name, target.reload),
    ]);
  }

  /// 푸시 종류 > 갱신 대상 (알 수 없는 종류·null은 알림 목록만, 채팅은 메시지 자체는 웹소켓 담당이라 미확인 개수만)
  List<ForegroundRefreshTarget> _resolveRefreshTargets(NotificationType? notificationType) {
    final ForegroundRefreshTarget notificationListTarget = (name: 'notification list', reload: reloadNotificationList);
    final ForegroundRefreshTarget sentTradeRequestsTarget = (
      name: 'sent trade requests',
      reload: reloadSentTradeRequests,
    );
    final ForegroundRefreshTarget chatRoomsTarget = (name: 'chat rooms', reload: reloadChatRooms);
    final ForegroundRefreshTarget myItemsTarget = (name: 'my items', reload: reloadMyItems);
    switch (notificationType) {
      case NotificationType.tradeRequestReceived:
        return [notificationListTarget, (name: 'received trade requests', reload: reloadReceivedTradeRequests)];
      case NotificationType.itemDeletedByAdmin:
        return [notificationListTarget, myItemsTarget];
      case NotificationType.chatMessageReceived:
        return [(name: 'notification unread count', reload: refreshNotificationUnreadCount)];
      // 수락 > 보낸 요청 상태 + 새 채팅방, 거절 > 보낸 요청 상태
      case NotificationType.tradeRequestAccepted:
        return [notificationListTarget, sentTradeRequestsTarget, chatRoomsTarget];
      case NotificationType.tradeRequestRejected:
        return [notificationListTarget, sentTradeRequestsTarget];
      // 완료 > 내 물품 교환 완료 + 채팅방 거래 상태
      case NotificationType.tradeCompleted:
        return [notificationListTarget, myItemsTarget, chatRoomsTarget];
      case NotificationType.tradeReviewReceived:
        return [notificationListTarget, (name: 'received reviews', reload: reloadReceivedReviews)];
      case NotificationType.itemLiked:
      case NotificationType.announcement:
      case NotificationType.unknown:
      case null:
        return [notificationListTarget];
    }
  }

  /// 갱신 1건 실행 (실패는 로그만 남기고 삼킴, 성공·실패와 무관하게 다른 갱신에 영향 없음)
  Future<void> _runSafely(String targetName, Future<void> Function() reload) async {
    try {
      await reload();
    } catch (error) {
      debugPrint('[foreground push refresh] $targetName failed : $error');
    }
  }
}
