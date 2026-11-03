import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/providers/user_scoped_providers.dart';
import 'package:romrom_fe/screens/account_suspended_screen.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/services/deep_link_gate.dart';
import 'package:romrom_fe/services/session_navigation_handler.dart';
import 'package:romrom_fe/utils/user_session_lifecycle.dart';

/// 세션 전환 검증: 종료 3종(제재·만료·로그아웃/탈퇴) 회원 자원 즉시 정리 + 대상 화면·전환 타입 + 전환 후 초기화·딥링크 게이트 닫힘, 로그인 성공 시 초기화 1회 후 이동
void main() {
  late List<ProviderOrFamily> invalidatedProviders;
  late List<String> callOrder;
  late List<(Widget, NavigationTypes)> navigations;
  late int releaseUserResourcesCallCount;

  setUp(() {
    invalidatedProviders = [];
    callOrder = [];
    navigations = [];
    releaseUserResourcesCallCount = 0;
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
      releaseUserResources: () async {
        releaseUserResourcesCallCount++;
        callOrder.add('release');
      },
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
      expect(callOrder.take(2), ['release', 'navigate']);
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

    testWidgets('세션 종료 > 딥링크 게이트 닫힘 (로그인·정지 화면 위 상세 화면 차단)', (tester) async {
      registerForTest();
      DeepLinkGate.instance.enterMainScreen();

      SessionNavigationHandler.notifySessionExpired();
      await tester.pump(previousScreensDisposeWait);

      expect(DeepLinkGate.instance.isMainScreenEntered, isFalse);
    });

    testWidgets('종료 3종 > 회원 단위 자원(웹소켓·하트비트·폴러) 정리를 화면 전환 전 즉시 1회씩', (tester) async {
      registerForTest();

      SessionNavigationHandler.notifyAccountSuspended(suspendReason: '욕설', suspendedUntil: '2026-11-01T00:00:00');
      expect(releaseUserResourcesCallCount, 1, reason: '정리 대기 없이 즉시');
      expect(callOrder.first, 'release');

      SessionNavigationHandler.notifySessionExpired();
      SessionNavigationHandler.notifyLoggedOut();
      expect(releaseUserResourcesCallCount, 3);
      await tester.pump(previousScreensDisposeWait);
    });

    testWidgets('자원 정리 실패 > 화면 전환·초기화는 그대로', (tester) async {
      registerSessionEndNavigation(
        invalidate: invalidatedProviders.add,
        navigate: (screen, type) => navigations.add((screen, type)),
        isActive: () => true,
        releaseUserResources: () async => throw StateError('release failed'),
      );

      SessionNavigationHandler.notifySessionExpired();
      await tester.pump(previousScreensDisposeWait);

      expect(navigations.single.$1, isA<LoginScreen>());
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
