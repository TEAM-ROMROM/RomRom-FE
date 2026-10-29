import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/services/session_navigation_handler.dart';

/// 세션 화면 전환 위임 검증: 미등록 notify 무시, 등록 후 notify > 해당 콜백 1회
void main() {
  tearDown(SessionNavigationHandler.unregister);

  test('미등록 상태 notify 3종 > 예외 없음', () {
    expect(() {
      SessionNavigationHandler.notifyAccountSuspended(suspendReason: '사유', suspendedUntil: '2026-11-01T00:00:00');
      SessionNavigationHandler.notifySessionExpired();
      SessionNavigationHandler.notifyLoggedOut();
    }, returnsNormally);
  });

  test('등록 후 notify > 해당 콜백만 1회, 제재 정보 그대로 전달', () {
    final suspendedCalls = <String>[];
    var sessionExpiredCallCount = 0;
    var loggedOutCallCount = 0;
    SessionNavigationHandler.register(
      onAccountSuspended: (suspendReason, suspendedUntil) => suspendedCalls.add('$suspendReason|$suspendedUntil'),
      onSessionExpired: () => sessionExpiredCallCount++,
      onLoggedOut: () => loggedOutCallCount++,
    );

    SessionNavigationHandler.notifyAccountSuspended(suspendReason: '욕설', suspendedUntil: '2026-11-01T00:00:00');
    expect(suspendedCalls, ['욕설|2026-11-01T00:00:00']);
    expect(sessionExpiredCallCount, 0);
    expect(loggedOutCallCount, 0);

    SessionNavigationHandler.notifySessionExpired();
    expect(sessionExpiredCallCount, 1);
    expect(loggedOutCallCount, 0);

    SessionNavigationHandler.notifyLoggedOut();
    expect(loggedOutCallCount, 1);
    expect(suspendedCalls.length, 1);
  });

  test('재등록 > 마지막 등록 콜백만 호출', () {
    var firstCallCount = 0;
    var secondCallCount = 0;
    SessionNavigationHandler.register(
      onAccountSuspended: (_, _) {},
      onSessionExpired: () => firstCallCount++,
      onLoggedOut: () {},
    );
    SessionNavigationHandler.register(
      onAccountSuspended: (_, _) {},
      onSessionExpired: () => secondCallCount++,
      onLoggedOut: () {},
    );

    SessionNavigationHandler.notifySessionExpired();

    expect(firstCallCount, 0);
    expect(secondCallCount, 1);
  });
}
