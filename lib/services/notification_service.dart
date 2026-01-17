import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 로컬 알림 플러그인 초기화
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> initNotificationPlugin() async {
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_push_notification');

  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: DarwinInitializationSettings(requestProvidesAppNotificationSettings: true));

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}
