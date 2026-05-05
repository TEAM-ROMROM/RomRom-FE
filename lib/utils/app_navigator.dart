import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/notification_type.dart';

/// 앱 전역 navigatorKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 콜드 스타트 딥링크 대기 데이터 (FCM / app_links 공용)
///
/// 앱 종료 상태에서 알림/링크로 진입 시 SplashScreen 내비게이션이 완료된 후
/// 딥링크 화면으로 이동하기 위해 임시 저장한다.
class ColdStartDeepLinkData {
  static Uri? _pendingUri;
  static NotificationType? _pendingNotificationType;

  static bool get hasPending => _pendingUri != null;
  static Uri? get pendingUri => _pendingUri;
  static NotificationType? get pendingNotificationType => _pendingNotificationType;

  static void setPending(Uri uri, {NotificationType? notificationType}) {
    _pendingUri = uri;
    _pendingNotificationType = notificationType;
  }

  static void clear() {
    _pendingUri = null;
    _pendingNotificationType = null;
  }
}
