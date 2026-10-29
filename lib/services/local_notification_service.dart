import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 로컬 알림 플러그인 초기화
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// 초기화 1회분 (첫 호출 Future 공유)
Future<void>? _notificationPluginInitialization;

/// 로컬 알림 플러그인 초기화 1회 (iOS: 권한 창 표시 후 응답까지 대기, 이후 호출은 같은 Future)
Future<void> initNotificationPlugin() {
  return _notificationPluginInitialization ??= _initializeNotificationPlugin();
}

Future<void> _initializeNotificationPlugin() async {
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(
    '@drawable/ic_push_notification',
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: DarwinInitializationSettings(requestProvidesAppNotificationSettings: true),
  );

  await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
}
