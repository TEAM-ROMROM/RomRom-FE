import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 알림 권한 유도 관련 로직 서비스
/// - 회원가입 직후 최초 1회 바텀시트 표시
/// - 앱 실행 시 7일 주기 바텀시트 재노출
/// - 모든 상태는 SharedPreferences 로컬 저장 (백엔드 불필요)
class NotificationPermissionService {
  static final NotificationPermissionService _instance = NotificationPermissionService._internal();
  factory NotificationPermissionService() => _instance;
  NotificationPermissionService._internal();

  static const String _kDismissedAtKey = 'notificationPermissionDismissedAt';
  static const String _kShownOnSignupKey = 'notificationPermissionShownOnSignup';
  static const Duration _kReshowInterval = Duration(days: 7);

  /// 알림 권한 허용 여부 확인
  /// Firebase Messaging 기준으로 확인 (앱 초기화 시 requestPermission과 동일한 채널)
  Future<bool> isPermissionGranted() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      final status = settings.authorizationStatus;
      final granted = status == AuthorizationStatus.authorized || status == AuthorizationStatus.provisional;
      debugPrint('[NotificationPermission] 현재 상태: $status → ${granted ? '허용됨' : '미허용'}');
      return granted;
    } catch (e) {
      debugPrint('[NotificationPermission] 상태 조회 실패: $e');
      return false;
    }
  }

  /// 바텀시트 표시 여부 결정
  ///
  /// [isSignup]: true → 회원가입 최초 1회 여부 체크
  ///             false → 7일 주기 재노출 여부 체크
  Future<bool> shouldShowBottomSheet({bool isSignup = false}) async {
    debugPrint('[NotificationPermission] 바텀시트 표시 여부 체크 (${isSignup ? '회원가입' : '7일 주기'})');

    if (await isPermissionGranted()) {
      debugPrint('[NotificationPermission] → 권한 이미 허용됨 → 바텀시트 표시 안 함');
      return false;
    }

    final prefs = await SharedPreferences.getInstance();

    if (isSignup) {
      final alreadyShown = prefs.getBool(_kShownOnSignupKey) ?? false;
      debugPrint('[NotificationPermission] → 회원가입 최초 노출 여부: ${alreadyShown ? '이미 노출됨 → 표시 안 함' : '미노출 → 표시'}');
      return !alreadyShown;
    }

    // 7일 주기 재노출 체크
    final dismissedAtStr = prefs.getString(_kDismissedAtKey);
    if (dismissedAtStr == null) {
      debugPrint('[NotificationPermission] → 이전 닫은 기록 없음 → 표시');
      return true;
    }
    final dismissedAt = DateTime.tryParse(dismissedAtStr);
    if (dismissedAt == null) {
      debugPrint('[NotificationPermission] → dismissedAt 파싱 실패 ($dismissedAtStr) → 표시');
      return true;
    }
    final elapsed = DateTime.now().difference(dismissedAt);
    final shouldShow = elapsed >= _kReshowInterval;
    debugPrint('[NotificationPermission] → 마지막 닫은 시각: $dismissedAt');
    debugPrint(
      '[NotificationPermission] → 경과: ${elapsed.inHours}시간 / 기준: ${_kReshowInterval.inDays}일 → ${shouldShow ? '표시' : '표시 안 함'}',
    );
    return shouldShow;
  }

  /// 회원가입 최초 노출 완료 기록
  Future<void> markShownOnSignup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShownOnSignupKey, true);
    debugPrint('[NotificationPermission] 회원가입 최초 노출 기록 저장 완료');
  }

  /// 바텀시트 노출 시점 기록 (7일 후 재노출 기준)
  /// "다음에", "알림 받기" 모두 호출하여 중복 노출 방지
  Future<void> recordDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    await prefs.setString(_kDismissedAtKey, now);
    debugPrint('[NotificationPermission] 바텀시트 닫힘 기록 저장 → $now (${_kReshowInterval.inDays}일 후 재노출)');
  }

  /// 알림 권한 요청 또는 시스템 설정 화면 이동
  ///
  /// Firebase로 권한 요청 시도 → 허용되지 않으면 앱 설정 화면으로 이동
  /// (앱 초기화 시 Firebase가 이미 시스템 팝업을 소진했으므로 Firebase 기준으로 처리)
  Future<void> requestOrOpenSettings() async {
    debugPrint('[NotificationPermission] 권한 요청 시작');
    final settings = await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    final status = settings.authorizationStatus;
    final granted = status == AuthorizationStatus.authorized || status == AuthorizationStatus.provisional;
    debugPrint('[NotificationPermission] 권한 요청 결과: $status → ${granted ? '허용' : '거부 → 설정 화면 이동'}');
    if (!granted) {
      await openAppSettings();
    }
  }

  /// 앱 시스템 설정 화면으로 바로 이동
  /// 사용자가 명시적으로 설정으로 이동을 선택한 경우 사용
  Future<void> openSettings() async {
    debugPrint('[NotificationPermission] 설정 화면으로 이동');
    await openAppSettings();
  }

  /// 로컬 알림 권한 관련 데이터 초기화 (회원탈퇴 시 호출)
  Future<void> clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDismissedAtKey);
    await prefs.remove(_kShownOnSignupKey);
    debugPrint('[NotificationPermission] 로컬 데이터 초기화 완료 (회원탈퇴)');
  }
}
