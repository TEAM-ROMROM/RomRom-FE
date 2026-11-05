import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:romrom_fe/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 알림 권한 상태 확인·설정 이동 서비스
/// - 권한 요청은 교환 요청·물품 등록·키워드 등록 성공 직후 1회 안내(NotificationPermissionPromptService)와 사용자가 누른 설정 동작에서만
/// - 상태 조회는 시스템 권한 창을 띄우지 않음
class NotificationPermissionService {
  static final NotificationPermissionService _instance = NotificationPermissionService._internal();
  factory NotificationPermissionService() => _instance;
  NotificationPermissionService._internal();

  // 이전 버전 바텀시트 노출 기록 키 (회원탈퇴 시 정리만)
  static const String _kDismissedAtKey = 'notificationPermissionDismissedAt';
  static const String _kShownOnSignupKey = 'notificationPermissionShownOnSignup';

  // 진행 중 권한 요청 응답 대기 (요청 없으면 즉시 완료, 새 요청 안 함, 테스트에서 교체)
  @visibleForTesting
  static Future<void> Function() waitForPendingPermissionRequest = FirebaseService().waitForPendingPermissionRequest;

  /// 알림 권한 허용 여부 확인
  /// Firebase Messaging 기준으로 확인 (시스템 권한 창 없음)
  Future<bool> isPermissionGranted() async {
    // 진행 중 권한 요청이 있으면 응답 후 상태 조회
    await waitForPendingPermissionRequest();
    final status = await _readAuthorizationStatus();
    if (status == null) return false;
    final granted = isGrantedStatus(status);
    debugPrint('[NotificationPermission] 현재 상태: $status → ${granted ? '허용됨' : '미허용'}');
    return granted;
  }

  /// 사용자가 알림 권한을 거부했는지 (미결정·허용·조회 실패 > false, 시스템 권한 창 없음)
  /// Android 13+는 미결정도 거부로 응답 > 거부로 판정
  Future<bool> isPermissionDeclined() async {
    await waitForPendingPermissionRequest();
    return await _readAuthorizationStatus() == AuthorizationStatus.denied;
  }

  /// 알림 권한 요청 또는 시스템 설정 화면 이동
  ///
  /// Firebase로 권한 요청 시도 → 허용되지 않으면 앱 설정 화면으로 이동 (사용자가 누른 동작에서만 호출)
  Future<void> requestOrOpenSettings() async {
    // 진행 중 권한 요청이 있으면 응답 후 재요청 (동시 requestPermission 충돌 방지)
    await waitForPendingPermissionRequest();
    debugPrint('[NotificationPermission] 권한 요청 시작');
    final settings = await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    final status = settings.authorizationStatus;
    final granted = isGrantedStatus(status);
    debugPrint('[NotificationPermission] 권한 요청 결과: $status → ${granted ? '허용' : '거부 → 설정 화면 이동'}');
    if (!granted) {
      await openAppSettings();
    }
  }

  /// 사용자가 누른 알림 켜기·설정 이동: 권한 미결정 > 시스템 권한 요청 + 허용 시 FCM 토큰 등록, 그 외 > 앱 설정 이동
  /// (iOS는 한 번도 요청하지 않은 앱의 설정에 알림 항목 없음 > 미결정이면 설정 이동 대신 요청)
  Future<void> openSettings() async {
    if (await _isPermissionUndetermined()) {
      debugPrint('[NotificationPermission] 미결정 > 시스템 권한 요청');
      await FirebaseService().requestNotificationPermission();
      if (await isPermissionGranted()) await FirebaseService().handleFcmToken();
      return;
    }
    debugPrint('[NotificationPermission] 설정 화면으로 이동');
    await openAppSettings();
  }

  /// 권한 미결정 여부 (iOS 미요청, 조회 실패 > false)
  Future<bool> _isPermissionUndetermined() async =>
      await _readAuthorizationStatus() == AuthorizationStatus.notDetermined;

  /// 허용 상태 판정 (authorized·provisional)
  static bool isGrantedStatus(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized || status == AuthorizationStatus.provisional;

  /// Firebase Messaging 권한 상태 조회 (시스템 권한 창 없음, 조회 실패 > null)
  Future<AuthorizationStatus?> _readAuthorizationStatus() async {
    try {
      return (await FirebaseMessaging.instance.getNotificationSettings()).authorizationStatus;
    } catch (e) {
      debugPrint('[NotificationPermission] 상태 조회 실패: $e');
      return null;
    }
  }

  /// 로컬 알림 권한 관련 데이터 초기화 (회원탈퇴 시 호출)
  Future<void> clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDismissedAtKey);
    await prefs.remove(_kShownOnSignupKey);
    debugPrint('[NotificationPermission] 로컬 데이터 초기화 완료 (회원탈퇴)');
  }
}
