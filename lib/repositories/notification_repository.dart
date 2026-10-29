import 'package:romrom_fe/models/apis/requests/notification_history_request.dart';
import 'package:romrom_fe/models/apis/responses/notification_history_response.dart';
import 'package:romrom_fe/services/apis/notification_api.dart';

/// 알림 API 래핑: 목록 조회, 미확인 개수, 읽음 처리, 삭제 (UI 모름)
class NotificationRepository {
  final NotificationApi _api;

  NotificationRepository(this._api);

  /// 알림 목록 1페이지 조회
  Future<NotificationHistoryResponse> getNotifications({required int pageNumber, required int pageSize}) =>
      _api.getUserNotifications(NotificationHistoryRequest(pageNumber: pageNumber, pageSize: pageSize));

  /// 미확인 알림 개수 (응답 없으면 0)
  Future<int> getUnreadCount() async => (await _api.getUnreadNotificationCount())?.unReadCount ?? 0;

  Future<void> markAsRead(String notificationHistoryId) => _api.updateNotificationsAsRead(notificationHistoryId);

  Future<void> markAllAsRead() => _api.updateAllNotificationsAsRead();

  Future<void> delete(String notificationHistoryId) =>
      _api.deleteNotification(NotificationHistoryRequest(notificationHistoryId: notificationHistoryId));

  Future<void> deleteAll() => _api.deleteAllNotifications();
}
