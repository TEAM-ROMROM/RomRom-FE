import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/apis/objects/notification_history.dart';

/// 알림 목록 상태: 불러온 알림, 미확인 개수, 다음 페이지 정보
@immutable
class NotificationListState {
  final List<NotificationHistory> notifications; // 불러온 페이지 전체 (서버 순서)
  final int unreadCount; // 홈 알림 배지 표시 기준
  final int nextPageNumber; // 다음 loadMore가 요청할 페이지 (= 불러온 페이지 수)
  final bool hasMore; // 서버에 남은 페이지 있음
  final bool isLoadingMore; // 다음 페이지 조회 중 (목록 끝 로딩 표시)

  NotificationListState({
    List<NotificationHistory> notifications = const [],
    this.unreadCount = 0,
    this.nextPageNumber = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
  }) : notifications = List.unmodifiable(notifications);

  NotificationListState copyWith({
    List<NotificationHistory>? notifications,
    int? unreadCount,
    int? nextPageNumber,
    bool? hasMore,
    bool? isLoadingMore,
  }) => NotificationListState(
    notifications: notifications ?? this.notifications,
    unreadCount: unreadCount ?? this.unreadCount,
    nextPageNumber: nextPageNumber ?? this.nextPageNumber,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationListState &&
          runtimeType == other.runtimeType &&
          listEquals(notifications, other.notifications) &&
          unreadCount == other.unreadCount &&
          nextPageNumber == other.nextPageNumber &&
          hasMore == other.hasMore &&
          isLoadingMore == other.isLoadingMore;

  @override
  int get hashCode => Object.hash(Object.hashAll(notifications), unreadCount, nextPageNumber, hasMore, isLoadingMore);

  @override
  String toString() =>
      'NotificationListState(notifications: ${notifications.length}, unreadCount: $unreadCount, '
      'nextPageNumber: $nextPageNumber, hasMore: $hasMore, isLoadingMore: $isLoadingMore)';
}
