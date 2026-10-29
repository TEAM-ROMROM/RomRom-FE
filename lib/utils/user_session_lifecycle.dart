import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/providers/user_scoped_providers.dart';
import 'package:romrom_fe/screens/account_suspended_screen.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/services/session_navigation_handler.dart';

/// 화면 전환 함수 (루트: navigatorKey 컨텍스트 + navigateTo)
typedef SessionScreenNavigator = void Function(Widget screen, NavigationTypes type);

/// 세션 종료 전환 후 이전 화면 정리 대기 (전환 최대 500ms(iOS 기본) + 여유)
const Duration previousScreensDisposeWait = Duration(seconds: 1);

// 대기 중인 세션 종료 초기화 (빠른 재로그인 시 startUserSession이 취소)
Timer? _pendingSessionEndReset;

/// 세션 종료 전환 등록 (앱 루트 1회): 제재·세션 만료·로그아웃(탈퇴 포함) > 대상 화면 전환 > 정리 대기 후 회원별 provider 초기화
/// 전환 전 초기화 금지: 사라지는 MainScreen 탭 구독이 토큰 없이 재조회 > 오류 상태·스낵바 잔류
void registerSessionEndNavigation({
  required void Function(ProviderOrFamily provider) invalidate,
  required SessionScreenNavigator navigate,
  required bool Function() isActive,
}) {
  void navigateThenReset(Widget screen, NavigationTypes type) {
    navigate(screen, type);
    _pendingSessionEndReset?.cancel();
    _pendingSessionEndReset = Timer(previousScreensDisposeWait, () {
      _pendingSessionEndReset = null;
      if (isActive()) invalidateUserScopedProviders(invalidate);
    });
  }

  SessionNavigationHandler.register(
    onAccountSuspended: (suspendReason, suspendedUntil) => navigateThenReset(
      AccountSuspendedScreen(suspendReason: suspendReason, suspendedUntil: suspendedUntil),
      NavigationTypes.clearStackImmediate,
    ),
    onSessionExpired: () => navigateThenReset(const LoginScreen(), NavigationTypes.fadeTransition),
    onLoggedOut: () => navigateThenReset(const LoginScreen(), NavigationTypes.pushAndRemoveUntil),
  );
}

/// 로그인 성공(소셜 로그인·자동 로그인): 대기 중 종료 초기화 취소 > 회원별 provider 초기화 1회 > 첫 화면(메인·온보딩) 이동
/// (로그인 화면은 회원 provider 미구독 > 즉시 초기화 안전, 빠른 재로그인에도 이전 계정 상태 차단)
void startUserSession({
  required void Function(ProviderOrFamily provider) invalidate,
  required VoidCallback navigateToSessionScreen,
}) {
  _pendingSessionEndReset?.cancel();
  _pendingSessionEndReset = null;
  invalidateUserScopedProviders(invalidate);
  navigateToSessionScreen();
}
