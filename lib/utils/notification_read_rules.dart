import 'package:romrom_fe/enums/notification_type.dart';
import 'package:romrom_fe/models/apis/objects/notification_history.dart';

/// 알림함 탭 소속: 공지(announcement) > 롬롬 소식 탭, 그 외 > 활동 및 채팅 탭
bool isRomromNewsNotification(NotificationHistory notification) =>
    notification.notificationType == NotificationType.announcement.serverName;

/// 방문한 탭의 읽지 않은 알림 id (불러온 목록 기준)
List<String> findUnreadNotificationIdsInTabs(
  List<NotificationHistory> notifications, {
  required bool isActivityTabIncluded,
  required bool isNewsTabIncluded,
}) {
  final unreadNotificationIds = <String>[];
  for (final notification in notifications) {
    final notificationId = notification.notificationHistoryId;
    if (notificationId == null || notification.isRead == true) continue;
    final isNewsNotification = isRomromNewsNotification(notification);
    final isInVisitedTab = isNewsNotification ? isNewsTabIncluded : isActivityTabIncluded;
    if (isInVisitedTab) unreadNotificationIds.add(notificationId);
  }
  return unreadNotificationIds;
}
