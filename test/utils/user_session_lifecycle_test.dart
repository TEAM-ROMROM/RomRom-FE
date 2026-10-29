import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/providers/user_scoped_providers.dart';
import 'package:romrom_fe/screens/account_suspended_screen.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/services/session_navigation_handler.dart';
import 'package:romrom_fe/utils/user_session_lifecycle.dart';

/// 세션 전환 검증: 종료 3종(제재·만료·로그아웃/탈퇴) 대상 화면·전환 타입 + 전환 후 초기화, 로그인 성공 시 초기화 1회 후 이동
void main() {
  late List<ProviderOrFamily> invalidatedProviders;
  late List<String> callOrder;
  late List<(Widget, NavigationTypes)> navigations;

  setUp(() {
    invalidatedProviders = [];
    callOrder = [];
    navigations = [];
  });
  tearDown(SessionNavigationHandler.unregister);

  void registerForTest({bool Function()? isActive}) {
    registerSessionEndNavigation(
      invalidate: (provider) {
        invalidatedProviders.add(provider);
        callOrder.add('invalidate');
      },
      navigate: (screen, type) {
        navigations.add((screen, type));
        callOrder.add('navigate');
      },
      isActive: isActive ?? () => true,
    );
  }

  group('세션 종료', () {
    testWidgets('로그아웃·회원 탈퇴(notifyLoggedOut) > LoginScreen pushAndRemoveUntil, 정리 대기 후 초기화 1회', (tester) async {
      registerForTest();

      SessionNavigationHandler.notifyLoggedOut();

      expect(navigations.single.$1, isA<LoginScreen>());
      expect(navigations.single.$2, NavigationTypes.pushAndRemoveUntil);
      expect(invalidatedProviders, isEmpty); // 이전 화면 구독 중 > 아직 초기화 안 함

      await tester.pump(previousScreensDisposeWait);

      expect(invalidatedProviders, userScopedProviders);
      expect(callOrder.first, 'navigate');
    });

    testWidgets('세션 만료 > LoginScreen fadeTransition, 정리 대기 후 초기화', (tester) async {
      registerForTest();

      SessionNavigationHandler.notifySessionExpired();
      await tester.pump(previousScreensDisposeWait);

      expect(navigations.single.$1, isA<LoginScreen>());
      expect(navigations.single.$2, NavigationTypes.fadeTransition);
      expect(invalidatedProviders, userScopedProviders);
    });

    testWidgets('제재 > AccountSuspendedScreen(사유·기한 전달) clearStackImmediate, 정리 대기 후 초기화', (tester) async {
      registerForTest();

      SessionNavigationHandler.notifyAccountSuspended(suspendReason: '욕설', suspendedUntil: '2026-11-01T00:00:00');
      await tester.pump(previousScreensDisposeWait);

      final suspendedScreen = navigations.single.$1 as AccountSuspendedScreen;
      expect(suspendedScreen.suspendReason, '욕설');
      expect(suspendedScreen.suspendedUntil, '2026-11-01T00:00:00');
      expect(navigations.single.$2, NavigationTypes.clearStackImmediate);
      expect(invalidatedProviders, userScopedProviders);
    });

    testWidgets('정리 대기 중 루트 해제 > 초기화 안 함', (tester) async {
      var isRootActive = true;
      registerForTest(isActive: () => isRootActive);

      SessionNavigationHandler.notifyLoggedOut();
      isRootActive = false;
      await tester.pump(previousScreensDisposeWait);

      expect(invalidatedProviders, isEmpty);
    });
  });

  testWidgets('로그아웃 직후 빠른 재로그인 > 대기 중 초기화 취소 (새 세션 중간 초기화 없음)', (tester) async {
    registerForTest();

    SessionNavigationHandler.notifyLoggedOut();
    startUserSession(invalidate: (provider) => invalidatedProviders.add(provider), navigateToSessionScreen: () {});
    expect(invalidatedProviders, userScopedProviders);

    await tester.pump(previousScreensDisposeWait);

    expect(invalidatedProviders, userScopedProviders, reason: '로그인 성공 시 1회만, 대기 초기화는 취소됨');
  });

  test('로그인 성공 > 초기화 1회(provider마다 1번) 후 화면 이동', () {
    startUserSession(
      invalidate: (provider) {
        invalidatedProviders.add(provider);
        callOrder.add('invalidate');
      },
      navigateToSessionScreen: () => callOrder.add('navigate'),
    );

    expect(invalidatedProviders, userScopedProviders);
    expect(callOrder.last, 'navigate');
    expect(callOrder.where((call) => call == 'navigate').length, 1);
    expect(callOrder.indexOf('navigate'), userScopedProviders.length);
  });
}
