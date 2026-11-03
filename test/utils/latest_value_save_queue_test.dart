import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/latest_value_save_queue.dart';

/// 저장 대역: 값별 결과 지정(기본 성공), 요청마다 대기 gate, 저장 순서 기록
class _RecordingSaver {
  final List<int> savedValues = [];
  final Set<int> failingValues = {};
  final Map<int, Completer<void>> gateByValue = {};

  Future<bool> save(int value) async {
    savedValues.add(value);
    final gate = gateByValue[value];
    if (gate != null) await gate.future;
    if (failingValues.contains(value)) throw Exception('save failed $value');
    return true;
  }
}

void main() {
  group('LatestValueSaveQueue', () {
    test('진행 중 요청 있으면 마지막 값만 대기 > 끝난 뒤 저장 (중간 값 건너뜀)', () async {
      final saver = _RecordingSaver()..gateByValue[1] = Completer<void>();
      final saveQueue = LatestValueSaveQueue<int>(saveValue: saver.save);

      final firstSave = saveQueue.save(1);
      final secondSave = saveQueue.save(2);
      final thirdSave = saveQueue.save(3);
      saver.gateByValue[1]!.complete();
      final result = await firstSave;

      expect(await secondSave, isNull, reason: '대기열로 합쳐진 요청은 결과 없음');
      expect(await thirdSave, isNull);
      expect(saver.savedValues, [1, 3]);
      expect(result?.lastSavedValue, 3);
      expect(result?.isLatestSaveFailed, false);
    });

    test('먼저 저장 성공 + 마지막 저장 실패 > 마지막 성공 값 유지, 실패 표시', () async {
      final saver = _RecordingSaver()
        ..gateByValue[1] = Completer<void>()
        ..failingValues.add(2);
      final saveQueue = LatestValueSaveQueue<int>(saveValue: saver.save);

      final firstSave = saveQueue.save(1);
      unawaited(saveQueue.save(2));
      saver.gateByValue[1]!.complete();
      final result = await firstSave;

      expect(result?.lastSavedValue, 1, reason: '성공 응답은 항상 저장 값에 반영');
      expect(result?.isLatestSaveFailed, true);
      expect(result?.latestSaveError, isA<Exception>());
    });

    test('중간 저장 실패 + 마지막 저장 성공 > 실패 아님', () async {
      final saver = _RecordingSaver()
        ..gateByValue[1] = Completer<void>()
        ..failingValues.add(1);
      final saveQueue = LatestValueSaveQueue<int>(saveValue: saver.save);

      final firstSave = saveQueue.save(1);
      unawaited(saveQueue.save(2));
      saver.gateByValue[1]!.complete();
      final result = await firstSave;

      expect(result?.lastSavedValue, 2);
      expect(result?.isLatestSaveFailed, false);
    });

    test('저장 결과 false > 실패로 처리', () async {
      final saveQueue = LatestValueSaveQueue<int>(saveValue: (_) async => false);

      final result = await saveQueue.save(1);

      expect(result?.lastSavedValue, isNull);
      expect(result?.isLatestSaveFailed, true);
      expect(result?.latestSaveError, isNull);
    });

    test('저장 끝난 뒤 새 요청 > 바로 저장', () async {
      final saver = _RecordingSaver();
      final saveQueue = LatestValueSaveQueue<int>(saveValue: saver.save);

      await saveQueue.save(1);
      await saveQueue.save(2);

      expect(saver.savedValues, [1, 2]);
    });
  });
}
