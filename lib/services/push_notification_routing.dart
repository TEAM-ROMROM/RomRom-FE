import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/notification_type.dart';
import 'package:romrom_fe/models/pending_deep_link.dart';
import 'package:romrom_fe/utils/deep_link_router.dart';

/// 푸시 알림 탭 공통 경로 3개: 콜드 스타트 FCM, 백그라운드 FCM 탭, Android 포그라운드 로컬 알림 탭
/// FCM data > 딥링크 > 딥링크 게이트 (로그인·온보딩 중이면 보관)

// 공지 상세 딥링크 접두사 (서버 AnnouncementEvent와 동일, #1007)
const String noticeDetailDeepLinkPrefix = 'romrom://notice/detail?announcementId=';

/// FCM data > 딥링크 문자열 (없으면 공지 푸시만 announcementId로 공지 상세 보정 — 딥링크 추가 전 서버 발송분)
String? resolvePushDeepLink(Map<String, dynamic> data) {
  final deepLink = data['deepLink'];
  if (deepLink is String && deepLink.isNotEmpty) return deepLink;
  final announcementId = data['announcementId'];
  final isAnnouncementPush = data['notificationType'] == NotificationType.announcement.serverName;
  if (isAnnouncementPush && announcementId is String && announcementId.isNotEmpty) {
    return '$noticeDetailDeepLinkPrefix$announcementId';
  }
  return null;
}

/// FCM data > 열 딥링크 (deepLink 없음·주소 오류 > null, 모르는 알림 타입은 타입 없이)
PendingDeepLink? buildPendingDeepLinkFromPushData(Map<String, dynamic> data) {
  final deepLink = resolvePushDeepLink(data);
  if (deepLink == null) return null;

  final uri = Uri.tryParse(deepLink);
  if (uri == null) return null;

  final typeRaw = data['notificationType'] as String?;
  final notificationType = NotificationType.fromServerName(typeRaw);
  if (typeRaw != null && notificationType == null) {
    debugPrint('[FCM] 알 수 없는 notificationType: $typeRaw');
  }
  return PendingDeepLink(uri: uri, notificationType: notificationType, extraData: data);
}

/// FCM data > 로컬 알림 payload (JSON 문자열)
String encodePushNotificationPayload(Map<String, dynamic> data) => jsonEncode(data);

/// 로컬 알림 payload > FCM data (없음·JSON 아님 > null)
Map<String, dynamic>? decodePushNotificationPayload(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  try {
    final decoded = jsonDecode(payload);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (error) {
    debugPrint('[FCM] local notification payload parse failed : $error');
    return null;
  }
}

/// FCM data > 딥링크 게이트 전달 (열 딥링크 없으면 무시)
void routePushNotificationData(Map<String, dynamic> data) {
  final pendingDeepLink = buildPendingDeepLinkFromPushData(data);
  if (pendingDeepLink == null) return;
  RomRomDeepLinkRouter.receive(pendingDeepLink);
}
