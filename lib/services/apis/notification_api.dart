import 'dart:io';

import 'package:flutter/material.dart';
import 'package:romrom_fe/models/apis/requests/notification_history_request.dart';
import 'package:romrom_fe/models/apis/responses/notification_history_response.dart';
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
  Future<void> saveFcmToken({required String fcmToken}) async {
    const String url = '${AppUrls.baseUrl}/api/notification/post/token';

    // 디바이스 타입 자동 감지 (IOS 또는 ANDROID)
    final String deviceType = Platform.isIOS ? 'IOS' : 'ANDROID';

    final Map<String, dynamic> fields = {'fcmToken': fcmToken, 'deviceType': deviceType};

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('FCM 토큰 저장 성공 (deviceType: $deviceType)');
      },
    );
  }

  /// 알림 읽음 처리
  /// `POST /api/notification/update/read`
  Future<void> updateNotificationsAsRead(List<String> notificationHistoryIds) async {
    const String url = '${AppUrls.baseUrl}/api/notification/update/read';

    final Map<String, dynamic> fields = {
      'notificationHistoryIds': notificationHistoryIds, // 읽음 처리할 알림 ID 리스트 (빈 리스트는 전체 읽음 처리 의미)
    };

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('알림 읽음 처리 성공');
      },
    );
  }

  /// 모든 알림 읽음 처리
  /// `POST /api/notification/update/all/read`
  Future<void> updateAllNotificationsAsRead() async {
    const String url = '${AppUrls.baseUrl}/api/notification/update/all/read';
    await ApiClient.sendMultipartRequest(
      url: url,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('모든 알림 읽음 처리 성공');
      },
    );
  }

  /// 안읽은 알림 개수 조회
  /// `POST /api/notification/get/un-read/count`
  Future<NotificationHistoryResponse> getUnreadNotificationCount() async {
    const String url = '${AppUrls.baseUrl}/api/notification/get/un-read/count';
    late NotificationHistoryResponse notificationResponse;

    await ApiClient.sendMultipartRequest(
      url: url,
      isAuthRequired: true,
      onSuccess: (responseData) {
        try {
          final Map<String, dynamic> responseMap = responseData;
          notificationResponse = NotificationHistoryResponse.fromJson(responseMap);
          debugPrint('안읽은 알림 개수 조회 성공: ${notificationResponse.unReadCount}개');
        } catch (e) {
          debugPrint('안읽은 알림 개수 파싱 실패: $e');
        }
      },
    );
    return notificationResponse;
  }

  /// 사용자 알림 목록 조회
  /// `POST /api/notification/get/notifications`
  Future<NotificationHistoryResponse> getUserNotifications(NotificationHistoryRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/notification/get/notifications';

    late NotificationHistoryResponse notificationResponse;

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: {'pageNumber': request.pageNumber.toString(), 'pageSize': request.pageSize.toString()},
      isAuthRequired: true,
      onSuccess: (responseData) {
        if (responseData != null && responseData['content'] != null) {
          try {
            final List<dynamic> content = responseData['content'];

            debugPrint('사용자 알림 목록 조회 성공: ${content.length}개');
            notificationResponse = NotificationHistoryResponse.fromJson(responseData);
          } catch (e) {
            debugPrint('사용자 알림 목록 파싱 실패: $e');
          }
        } else {
          debugPrint('사용자 알림 목록 조회 실패: 응답 데이터 형식 오류');
        }
      },
    );

    return notificationResponse;
  }

  /// 알림 삭제
  /// `POST /api/notification/delete`
  Future<void> deleteNotification(NotificationHistoryRequest request) async {
    const String url = '${AppUrls.baseUrl}/api/notification/delete';

    final Map<String, dynamic> fields = {'notificationHistoryIds': request.notificationHistoryId};

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('알림 삭제 성공');
      },
    );
  }

  /// 전체 알림 삭제
  /// `POST /api/notification/delete/all`
  Future<void> deleteAllNotifications() async {
    const String url = '${AppUrls.baseUrl}/api/notification/delete/all';
    await ApiClient.sendMultipartRequest(
      url: url,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('모든 알림 삭제 성공');
      },
    );
  }
}
