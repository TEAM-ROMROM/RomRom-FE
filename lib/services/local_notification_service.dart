import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 로컬 알림 플러그인 초기화
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// 초기화 1회분 (첫 호출 Future 공유)
Future<void>? _notificationPluginInitialization;

/// 로컬 알림 플러그인 초기화 1회 (권한 요청 없음 > 권한은 FCM 요청 경로에서만, 이후 호출은 같은 Future)
Future<void> initNotificationPlugin() {
  return _notificationPluginInitialization ??= _initializeNotificationPlugin();
}

Future<void> _initializeNotificationPlugin() async {
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(
    '@drawable/ic_push_notification',
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    // iOS 초기화 시 권한 창 금지 (기본값 true > 시작 시 권한 창 노출)
    iOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      requestProvidesAppNotificationSettings: false,
    ),
  );

  await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
}
