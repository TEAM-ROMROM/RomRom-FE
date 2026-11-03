import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/notification_type.dart';

/// 열 딥링크 1건: 주소, 알림 타입(푸시·알림함), 부가 값(FCM data·알림 payload)
@immutable
class PendingDeepLink {
  final Uri uri;
  final NotificationType? notificationType;
  // deepLink 쿼리로 못 싣는 값 (예: itemName, deleteReason)
  final Map<String, dynamic>? extraData;

  const PendingDeepLink({required this.uri, this.notificationType, this.extraData});

  @override
  String toString() => 'PendingDeepLink(uri: $uri, notificationType: $notificationType)';
}
