import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/concurrency_limiter.dart';

/// 동시 실행 제한 검증: 최대 동시 수, 대기 순서(FIFO), 실패·동기 예외 시 슬롯 반환, 결과 전달
void main() {
  test('최대 2개 > 5개 요청 중 동시 실행 2개, 나머지 대기', () async {
    final limiter = ConcurrencyLimiter(maximumConcurrentCount: 2);
    final taskCompleters = List.generate(5, (_) => Completer<int>());
    var runningCount = 0;
    var maximumObservedRunningCount = 0;

    final results = [
      for (var index = 0; index < 5; index++)
        limiter.run(() async {
          runningCount++;
          maximumObservedRunningCount = runningCount > maximumObservedRunningCount
              ? runningCount
              : maximumObservedRunningCount;
          final completedIndex = await taskCompleters[index].future;
          runningCount--;
          return completedIndex;
        }),
    ];
    await pumpEventQueue();
    expect(limiter.runningCount, 2);
    expect(limiter.waitingCount, 3);

    for (var index = 0; index < 5; index++) {
      taskCompleters[index].complete(index);
      await pumpEventQueue();
    }

    expect(await Future.wait(results), [0, 1, 2, 3, 4]);
    expect(maximumObservedRunningCount, 2);
    expect(limiter.runningCount, 0);
    expect(limiter.waitingCount, 0);
  });

  test('대기 작업은 요청 순서대로 시작 (FIFO)', () async {
    final limiter = ConcurrencyLimiter(maximumConcurrentCount: 1);
    final startedOrder = <int>[];
    final firstTaskCompleter = Completer<void>();

    final firstRun = limiter.run(() async {
      startedOrder.add(0);
      await firstTaskCompleter.future;
    });
    final waitingRuns = [for (var index = 1; index <= 3; index++) limiter.run(() async => startedOrder.add(index))];
    await pumpEventQueue();
    expect(startedOrder, [0]);

    firstTaskCompleter.complete();
    await firstRun;
    await Future.wait(waitingRuns);

    expect(startedOrder, [0, 1, 2, 3]);
  });

  test('작업 실패 > 예외 전달, 슬롯 반환 후 다음 작업 실행', () async {
    final limiter = ConcurrencyLimiter(maximumConcurrentCount: 1);

    final failingRun = limiter.run<int>(() async => throw StateError('failed'));
    final nextRun = limiter.run(() async => 7);

    await expectLater(failingRun, throwsStateError);
    expect(await nextRun, 7);
    expect(limiter.runningCount, 0);
  });

  test('작업 동기 예외 > Future 에러로 전달, 슬롯 반환', () async {
    final limiter = ConcurrencyLimiter(maximumConcurrentCount: 1);

    final failingRun = limiter.run<int>(() => throw ArgumentError('sync failure'));

    await expectLater(failingRun, throwsArgumentError);
    expect(await limiter.run(() async => 1), 1);
    expect(limiter.runningCount, 0);
  });

  test('최대 동시 수 0 이하 > 생성 시 오류', () {
    expect(() => ConcurrencyLimiter(maximumConcurrentCount: 0), throwsArgumentError);
  });
}
