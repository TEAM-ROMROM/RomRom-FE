import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// 로그아웃 시 FCM 토큰 조회 대기 상한 (로그아웃 지연 방지)
const Duration logoutFcmTokenTimeout = Duration(seconds: 2);

/// 로그아웃용 현재 FCM 토큰 (시간 초과·오류·빈 값 > null, 예외 밖으로 던지지 않음)
/// [readFcmToken] 미지정 > FirebaseMessaging 토큰 (테스트 대역 주입용)
Future<String?> readFcmTokenForLogout({
  Future<String?> Function()? readFcmToken,
  Duration timeout = logoutFcmTokenTimeout,
}) async {
  try {
    final fcmToken = await (readFcmToken ?? FirebaseMessaging.instance.getToken)().timeout(timeout);
    if (fcmToken == null || fcmToken.isEmpty) return null;
    return fcmToken;
  } catch (error) {
    debugPrint('[logout] fcm token unavailable : $error');
    return null;
  }
}
