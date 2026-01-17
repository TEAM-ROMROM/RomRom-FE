import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:romrom_fe/services/notification_service.dart';
import 'package:romrom_fe/services/apis/notification_api.dart';

class FirebaseService {
  // Foreground 메시지를 UI에서 구독할 수 있도록 브로드캐스트 스트림 제공
  final StreamController<RemoteMessage> _foregroundMessageController = StreamController<RemoteMessage>.broadcast();

  /// 포그라운드에서 들어오는 메시지 스트림
  Stream<RemoteMessage> get onForegroundMessage => _foregroundMessageController.stream;

  /// 서비스 정리 (앱 종료 또는 필요 시 호출)
  void dispose() {
    try {
      _foregroundMessageController.close();
    } catch (_) {}
  }

  /// 알림 권한 요청 세팅
  Future<void> setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 알림 권한 요청 (iOS)
    NotificationSettings settings = await messaging.requestPermission(alert: true, badge: true, sound: true);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('[FCM] 푸시 알림 권한이 허용됨');
    } else {
      debugPrint('[FCM] 푸시 알림 권한이 거부됨');
    }

    // 앱이 포그라운드에 있을 때 (인앱 표시 처리용으로 스트림에 전달)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      try {
        _foregroundMessageController.add(message);

        final notification = message.notification;
        final android = message.notification?.android;

        if (notification != null && android != null) {
          // flutter_local_notifications 이용 (use shared initialized plugin)
          await flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'High Importance Notifications',
                importance: Importance.max,
                priority: Priority.high,
                color: Color(0xFF1D1E27),
                colorized: true,
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('[FCM] Foreground stream add error: $e');
      }

      if (message.notification != null) {
        debugPrint("[FCM] 푸시 알림 도착: ${message.notification!.title}, ${message.notification!.body}");
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("[FCM] 알림 클릭 후 앱이 열림: ${message.notification!.title}");
    });
  }

  /// FCM 토큰 발급 및 갱신
  /// 온보딩 완료 또는 토큰 갱신 시 호출
  Future<String?> getFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // FCM 토큰 발급
      final token = await messaging.getToken();
      if (token != null) {
        debugPrint('[FCM] 토큰 발급 성공: $token');
        return token;
      } else {
        debugPrint('[FCM] 토큰 발급 실패');
        return null;
      }
    } catch (e) {
      debugPrint('[FCM] 토큰 발급 중 오류: $e');
      return null;
    }
  }

  /// FCM 토큰 갱신 감지 및 처리
  /// 토큰이 갱신될 때마다 콜백 실행
  void onTokenRefresh({required Function(String) onTokenRefreshed}) {
    FirebaseMessaging.instance.onTokenRefresh
        .listen((newToken) {
          debugPrint('[FCM] 토큰 갱신됨: $newToken');
          onTokenRefreshed(newToken);
        })
        .onError((err) {
          debugPrint('[FCM] 토큰 갱신 감지 중 오류: $err');
        });
  }

  /// FCM 토큰 발급 및 백엔드 저장
  /// 온보딩 완료 시 호출
  Future<void> handleFcmToken() async {
    try {
      final notificationApi = NotificationApi();

      // 1. FCM 토큰 발급
      final fcmToken = await getFcmToken();
      if (fcmToken == null) {
        debugPrint('[FCM] FCM 토큰 발급 실패');
        return;
      }

      // 2. 백엔드에 FCM 토큰 저장
      await notificationApi.saveFcmToken(fcmToken: fcmToken);
      debugPrint('[FCM] FCM 토큰 저장 완료');

      // 3. 토큰 갱신 감지 설정
      setupTokenRefreshListener(notificationApi);
    } catch (e) {
      debugPrint('[FCM] FCM 토큰 발급/저장 중 오류: $e');
    }
  }

  /// FCM 토큰 갱신 감지 및 자동 저장
  void setupTokenRefreshListener(NotificationApi notificationApi) {
    debugPrint('[FCM] 토큰 셋업 : 토큰 갱신 리스너 설정 시작');
    onTokenRefresh(
      onTokenRefreshed: (String newToken) async {
        try {
          await notificationApi.saveFcmToken(fcmToken: newToken);
          debugPrint('[FCM] 갱신된 FCM 토큰 저장 완료: $newToken');
        } catch (e) {
          debugPrint('[FCM] 갱신된 FCM 토큰 저장 실패: $e');
        }
      },
    );
  }
}
