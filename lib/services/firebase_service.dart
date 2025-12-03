import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:romrom_fe/firebase_options.dart';

class FirebaseService {
  Future<void> verifyFirebase() async {
    // 1) 초기화 안돼있으면 초기화
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // 2) 현재 Firebase App/Project 정보 출력
    final app = Firebase.app();
    final opts = app.options;
    // Firebase 콘솔 프로젝트 ID가 찍혀야 정상
    debugPrint(
      '[Firebase] appName=${app.name} projectId=${opts.projectId} appId=${opts.appId}',
    );

    // 3) FCM 토큰 확인 (네트워크까지 정상이어야 발급됨)
    final fm = FirebaseMessaging.instance;
    final settings = await fm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] permission=${settings.authorizationStatus}');
    final token = await fm.getToken();
    if (token != null) {
      // 토큰을 Firestore에 저장
      debugPrint("✅ [FCM] 기기 토큰 저장 성공: $token");
    } else {
      debugPrint("❌ [FCM] 기기 토큰을 가져오는 데 실패했습니다.");
    }

    // 4) 포그라운드 메시지 핸들러 1회 바인딩(수신 여부 로그)
    FirebaseMessaging.onMessage.listen((m) {
      debugPrint(
        '[FCM] onMessage title=${m.notification?.title} body=${m.notification?.body} data=${m.data}',
      );
    });
  }

  /// 알림 권한 요청 세팅
  Future<void> setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 알림 권한 요청 (iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('푸시 알림 권한이 허용됨');
    } else {
      debugPrint('푸시 알림 권한이 거부됨');
    }

    // 앱이 포그라운드에 있을 때 (알림이 화면에 뜨지는 않음)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        debugPrint(
          "푸시 알림 도착: ${message.notification!.title}, ${message.notification!.body}",
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("알림 클릭 후 앱이 열림: ${message.notification!.title}");
    });
  }
}
