import 'dart:io';

import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/services/api_client.dart';

/// 알림 관련 API
class NotificationApi {
  // 싱글톤 구현
  static final NotificationApi _instance = NotificationApi._internal();

  factory NotificationApi() => _instance;

  NotificationApi._internal();

  /// FCM 토큰 저장 API
  /// `POST /api/notification/post/token`
  Future<void> saveFcmToken({
    required String fcmToken,
  }) async {
    const String url = '${AppUrls.baseUrl}/api/notification/post/token';

    // 디바이스 타입 자동 감지 (IOS 또는 ANDROID)
    final String deviceType = Platform.isIOS ? 'IOS' : 'ANDROID';

    final Map<String, dynamic> fields = {
      'fcmToken': fcmToken,
      'deviceType': deviceType,
    };

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('FCM 토큰 저장 성공 (deviceType: $deviceType)');
      },
    );
  }

  /// 특정 사용자에게 푸시 전송 API
  /// `POST /api/notification/send/members`
  Future<void> sendToMembers({
    required List<String> memberIds,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    const String url = '${AppUrls.baseUrl}/api/notification/send/members';

    final Map<String, dynamic> fields = {
      'memberIds': memberIds.join(','),
      'title': title,
      'body': body,
      if (data != null) 'data': data.toString(),
    };

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('특정 사용자 푸시 전송 성공');
      },
    );
  }

  /// 전체 사용자에게 푸시 전송 API
  /// `POST /api/notification/send/all`
  Future<void> sendToAll({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    const String url = '${AppUrls.baseUrl}/api/notification/send/all';

    final Map<String, dynamic> fields = {
      'title': title,
      'body': body,
      if (data != null) 'data': data.toString(),
    };

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('전체 사용자 푸시 전송 성공');
      },
    );
  }
}