import 'dart:io';

import 'package:flutter/material.dart';
import 'package:romrom_fe/models/apis/requests/notification_history_request.dart';
import 'package:romrom_fe/models/apis/responses/announcement_response.dart';
import 'package:romrom_fe/models/apis/responses/notification_history_response.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/services/api_client.dart';

/// 알림 관련 API
class NotificationApi {
  // 싱글톤 구현
  static final NotificationApi _instance = NotificationApi._internal();

  factory NotificationApi() => _instance;

  NotificationApi._internal();

  // 확장 알림 타입(수락·거절·완료·후기) 표시 가능 앱 표시 > 서버가 목록·미확인 개수에 포함 (BE #861)
  static const Map<String, String> _extendedTypeSupportedFields = {'isExtendedTypeSupported': 'true'};

  /// FCM 토큰 저장 API
  /// `POST /api/notification/post/token`
  Future<void> saveFcmToken({required String fcmToken}) async {
    final String url = '${AppUrls.baseUrl}/api/notification/post/token';

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
  Future<void> updateNotificationsAsRead(String notificationHistoryId) async {
    final String url = '${AppUrls.baseUrl}/api/notification/update/read';

    final Map<String, dynamic> fields = {
      'notificationHistoryId': notificationHistoryId, // 읽음 처리할 알림 ID(단건)
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
    final String url = '${AppUrls.baseUrl}/api/notification/update/all/read';
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
  Future<NotificationHistoryResponse?> getUnreadNotificationCount() async {
    final String url = '${AppUrls.baseUrl}/api/notification/get/un-read/count';
    NotificationHistoryResponse? notificationResponse;

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: _extendedTypeSupportedFields,
      isAuthRequired: true,
      onSuccess: (responseData) {
        try {
          final Map<String, dynamic> responseMap = responseData;
          notificationResponse = NotificationHistoryResponse.fromJson(responseMap);
          debugPrint('안읽은 알림 개수 조회 성공: ${notificationResponse!.unReadCount}개');
        } catch (e) {
          debugPrint('안읽은 알림 개수 파싱 실패: $e');
        }
      },
    );
    if (notificationResponse == null) {
      throw StateError('안읽은 알림 개수 조회 응답이 비어있습니다.');
    }
    return notificationResponse;
  }

  /// 사용자 알림 목록 조회
  /// `POST /api/notification/get/notifications`
  Future<NotificationHistoryResponse> getUserNotifications(NotificationHistoryRequest request) async {
    final String url = '${AppUrls.baseUrl}/api/notification/get/notifications';

    late NotificationHistoryResponse notificationResponse;

    final Map<String, dynamic> fields = {
      'pageNumber': request.pageNumber.toString(),
      'pageSize': request.pageSize.toString(),
      ..._extendedTypeSupportedFields,
    };

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {
        try {
          notificationResponse = NotificationHistoryResponse.fromJson(responseData);
        } catch (e) {
          debugPrint('사용자 알림 목록 파싱 실패: $e');
        }
      },
    );

    return notificationResponse;
  }

  /// 알림 삭제
  /// `POST /api/notification/delete`
  Future<void> deleteNotification(NotificationHistoryRequest request) async {
    final String url = '${AppUrls.baseUrl}/api/notification/delete';

    final Map<String, dynamic> fields = {'notificationHistoryId': request.notificationHistoryId};

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
    final String url = '${AppUrls.baseUrl}/api/notification/delete/all';
    await ApiClient.sendMultipartRequest(
      url: url,
      isAuthRequired: true,
      onSuccess: (_) {
        debugPrint('모든 알림 삭제 성공');
      },
    );
  }

  /// 공지 상세 조회 (BE #861)
  /// `POST /api/notification/get/announcement`
  Future<AnnouncementResponse> getAnnouncementDetail(String announcementId) async {
    final String url = '${AppUrls.baseUrl}/api/notification/get/announcement';
    AnnouncementResponse? announcementResponse;

    await ApiClient.sendMultipartRequest(
      url: url,
      fields: {'announcementId': announcementId},
      isAuthRequired: true,
      onSuccess: (responseData) {
        announcementResponse = AnnouncementResponse.fromJson(responseData);
      },
    );
    if (announcementResponse == null) {
      throw StateError('공지 상세 조회 응답이 비어있습니다.');
    }
    return announcementResponse!;
  }
}
