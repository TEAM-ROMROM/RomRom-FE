import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/pending_deep_link.dart';

/// 딥링크 진입 게이트: 메인 화면 진입 전 링크 보관, 진입 시 1회 전달, 세션 종료 시 다시 보관 모드
/// 로그인·온보딩·정지 화면 위에 상세 화면이 쌓이지 않게 모든 링크 진입(콜드 스타트·실행 중·푸시 탭)이 거침
class DeepLinkGate {
  DeepLinkGate();

  // 앱 전체 공용 인스턴스 (테스트는 새 인스턴스 생성)
  static final DeepLinkGate instance = DeepLinkGate();

  bool _isMainScreenEntered = false;
  PendingDeepLink? _pendingDeepLink;

  bool get isMainScreenEntered => _isMainScreenEntered;
  bool get hasPendingDeepLink => _pendingDeepLink != null;

  /// 링크 수신: 메인 진입 상태면 바로 열 링크 반환, 아니면 보관 후 null
  /// 보관 우선순위: 알림 링크 > 일반 링크 (보관 중 알림 링크를 일반 링크가 덮지 않음)
  PendingDeepLink? receive(PendingDeepLink deepLink) {
    if (_isMainScreenEntered) return deepLink;
    final pendingDeepLink = _pendingDeepLink;
    final isKeepingNotificationLink =
        pendingDeepLink != null && pendingDeepLink.notificationType != null && deepLink.notificationType == null;
    if (!isKeepingNotificationLink) _pendingDeepLink = deepLink;
    return null;
  }

  /// 메인 화면 진입: 열림 상태 전환 > 보관 링크 꺼내기 (1회)
  PendingDeepLink? enterMainScreen() {
    _isMainScreenEntered = true;
    final pendingDeepLink = _pendingDeepLink;
    _pendingDeepLink = null;
    return pendingDeepLink;
  }

  /// 세션 종료(로그아웃·만료·정지·탈퇴): 보관 모드 전환
  /// 메인 진입한 세션이 끝난 경우만 보관 링크 폐기 (온보딩 이탈·시작 실패 탈출은 로그인 후 이어 열기)
  void leaveMainScreen() {
    if (_isMainScreenEntered) _pendingDeepLink = null;
    _isMainScreenEntered = false;
  }

  @visibleForTesting
  void resetForTest() {
    _isMainScreenEntered = false;
    _pendingDeepLink = null;
  }
}
