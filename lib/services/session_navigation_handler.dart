import 'package:flutter/foundation.dart';

/// 세션 종료 화면 전환 위임: 서비스(ApiClient·AuthService) > 앱 루트 등록 콜백
/// 콜백 3개: 제재, 세션 만료, 로그아웃 / 미등록 시 로그만 남기고 무시 (서비스의 화면 import 제거용)
class SessionNavigationHandler {
  SessionNavigationHandler._();

  static void Function(String suspendReason, String suspendedUntil)? _onAccountSuspended;
  static void Function()? _onSessionExpired;
  static void Function()? _onLoggedOut;

  /// 앱 루트 콜백 등록 (재등록 시 마지막 등록만 유효)
  static void register({
    required void Function(String suspendReason, String suspendedUntil) onAccountSuspended,
    required void Function() onSessionExpired,
    required void Function() onLoggedOut,
  }) {
    _onAccountSuspended = onAccountSuspended;
    _onSessionExpired = onSessionExpired;
    _onLoggedOut = onLoggedOut;
  }

  /// 등록 콜백 해제 (테스트 격리용)
  @visibleForTesting
  static void unregister() {
    _onAccountSuspended = null;
    _onSessionExpired = null;
    _onLoggedOut = null;
  }

  /// 제재(403 SUSPENDED_MEMBER) > 제재 안내 화면 전환 요청
  static void notifyAccountSuspended({required String suspendReason, required String suspendedUntil}) {
    final onAccountSuspended = _onAccountSuspended;
    if (onAccountSuspended == null) return _logUnregistered('account suspended');
    onAccountSuspended(suspendReason, suspendedUntil);
  }

  /// 세션 만료(EXPIRED_REFRESH_TOKEN) > 로그인 화면 전환 요청
  static void notifySessionExpired() {
    final onSessionExpired = _onSessionExpired;
    if (onSessionExpired == null) return _logUnregistered('session expired');
    onSessionExpired();
  }

  /// 로그아웃 완료 > 로그인 화면 전환 요청
  static void notifyLoggedOut() {
    final onLoggedOut = _onLoggedOut;
    if (onLoggedOut == null) return _logUnregistered('logged out');
    onLoggedOut();
  }

  static void _logUnregistered(String sessionEvent) {
    debugPrint('[session navigation] ignored $sessionEvent : handler not registered');
  }
}
