import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/app_update_type.dart';
import 'package:romrom_fe/services/splash_startup_sequence.dart';

void main() {
  // testWidgets: Future.delayed 가 가짜 시계로 동작 (pump 로 시간 진행)
  const Duration minimumSplashDuration = Duration(seconds: 2);

  group('runSplashStartupSequence', () {
    testWidgets('강제 업데이트 > 초기 화면 결정 미호출, 최소 노출 시간 대기 없이 즉시 반환', (tester) async {
      var determineCallCount = 0;
      SplashStartupResult<String>? startupResult;

      unawaited(
        runSplashStartupSequence<String>(
          checkUpdateType: () async => UpdateType.force,
          determineInitialScreen: () async {
            determineCallCount++;
            return 'main';
          },
          isAborted: () => false,
          minimumSplashDuration: minimumSplashDuration,
        ).then((result) => startupResult = result),
      );
      await tester.pump();

      expect(startupResult?.isForcedUpdate, isTrue);
      expect(startupResult?.nextScreen, isNull);
      expect(determineCallCount, 0);
      await tester.pump(minimumSplashDuration); // 남은 타이머 정리
    });

    testWidgets('최소 노출 시간은 버전 확인과 동시에 시작 > 1.5초 버전 확인 후 2초 시점 완료', (tester) async {
      final versionCompleter = Completer<UpdateType>();
      var isDetermineCalledBeforeVersion = false;
      SplashStartupResult<String>? startupResult;

      unawaited(
        runSplashStartupSequence<String>(
          checkUpdateType: () => versionCompleter.future,
          determineInitialScreen: () async {
            isDetermineCalledBeforeVersion = !versionCompleter.isCompleted;
            return 'main';
          },
          isAborted: () => false,
          minimumSplashDuration: minimumSplashDuration,
        ).then((result) => startupResult = result),
      );

      await tester.pump(const Duration(milliseconds: 1500));
      versionCompleter.complete(UpdateType.none);
      await tester.pump(const Duration(milliseconds: 400)); // 1.9초
      expect(startupResult, isNull);

      await tester.pump(const Duration(milliseconds: 100)); // 2.0초 (순차 실행이면 3.5초)
      expect(startupResult?.nextScreen, 'main');
      expect(startupResult?.isForcedUpdate, isFalse);
      expect(isDetermineCalledBeforeVersion, isFalse);
    });

    testWidgets('권장·불필요 업데이트 > 일반 경로', (tester) async {
      SplashStartupResult<String>? startupResult;

      unawaited(
        runSplashStartupSequence<String>(
          checkUpdateType: () async => UpdateType.recommend,
          determineInitialScreen: () async => 'login',
          isAborted: () => false,
          minimumSplashDuration: minimumSplashDuration,
        ).then((result) => startupResult = result),
      );
      await tester.pump(minimumSplashDuration);

      expect(startupResult?.nextScreen, 'login');
    });

    testWidgets('버전 확인 중 중단 > 초기 화면 결정 미호출', (tester) async {
      var determineCallCount = 0;
      SplashStartupResult<String>? startupResult;

      unawaited(
        runSplashStartupSequence<String>(
          checkUpdateType: () async => UpdateType.force,
          determineInitialScreen: () async {
            determineCallCount++;
            return 'main';
          },
          isAborted: () => true,
          minimumSplashDuration: minimumSplashDuration,
        ).then((result) => startupResult = result),
      );
      await tester.pump(minimumSplashDuration);

      expect(startupResult?.isAborted, isTrue);
      expect(determineCallCount, 0);
    });

    testWidgets('초기 화면 결정 중 중단 > 중단 결과', (tester) async {
      var isAborted = false;
      SplashStartupResult<String>? startupResult;

      unawaited(
        runSplashStartupSequence<String>(
          checkUpdateType: () async => UpdateType.none,
          determineInitialScreen: () async {
            isAborted = true; // 타임아웃이 결정 도중 발생한 상황
            return 'main';
          },
          isAborted: () => isAborted,
          minimumSplashDuration: minimumSplashDuration,
        ).then((result) => startupResult = result),
      );
      await tester.pump(minimumSplashDuration);

      expect(startupResult?.isAborted, isTrue);
      expect(startupResult?.nextScreen, isNull);
    });

    testWidgets('초기 화면 결정 오류 > 최소 노출 시간 후 같은 오류 전달', (tester) async {
      Object? caughtError;

      unawaited(
        runSplashStartupSequence<String>(
          checkUpdateType: () async => UpdateType.none,
          determineInitialScreen: () async => throw const SocketExceptionStub(),
          isAborted: () => false,
          minimumSplashDuration: minimumSplashDuration,
        ).then<void>((_) {}, onError: (Object error) => caughtError = error),
      );
      await tester.pump(const Duration(milliseconds: 1900));
      expect(caughtError, isNull);

      await tester.pump(const Duration(milliseconds: 100));
      expect(caughtError, isA<SocketExceptionStub>());
    });
  });
}

/// 네트워크 오류 대역 (dart:io SocketException 대신 순수 타입)
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
