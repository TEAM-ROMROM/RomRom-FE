import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/single_flight.dart';

void main() {
  group('SingleFlight', () {
    test('동시 3회 run > task 1회 호출, 세 결과 동일', () async {
      final singleFlight = SingleFlight<int>();
      final taskCompleter = Completer<int>();
      var taskCallCount = 0;

      Future<int> task() {
        taskCallCount++;
        return taskCompleter.future;
      }

      final futures = [singleFlight.run(task), singleFlight.run(task), singleFlight.run(task)];
      expect(singleFlight.isRunning, isTrue);

      taskCompleter.complete(42);
      final results = await Future.wait(futures);

      expect(taskCallCount, 1);
      expect(results, [42, 42, 42]);
    });

    test('첫 task throw > 세 호출 모두 같은 에러, 이후 run 은 task 새로 호출', () async {
      final singleFlight = SingleFlight<int>();
      final taskCompleter = Completer<int>();
      final taskError = StateError('reissue failed');
      var taskCallCount = 0;

      Future<int> failingTask() {
        taskCallCount++;
        return taskCompleter.future;
      }

      final futures = [singleFlight.run(failingTask), singleFlight.run(failingTask), singleFlight.run(failingTask)];
      taskCompleter.completeError(taskError);

      for (final future in futures) {
        await expectLater(future, throwsA(same(taskError)));
      }

      final nextResult = await singleFlight.run(() async {
        taskCallCount++;
        return 7;
      });

      expect(taskCallCount, 2);
      expect(nextResult, 7);
    });

    test('완료 후 isRunning false', () async {
      final singleFlight = SingleFlight<String>();

      await singleFlight.run(() async => 'done');

      expect(singleFlight.isRunning, isFalse);
    });
  });
}
