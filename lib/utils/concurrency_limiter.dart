import 'dart:async';
import 'dart:collection';

/// 비동기 작업 동시 실행 수 제한: 초과분 대기열(FIFO), 작업 종료 시 다음 대기 작업 시작 (성공·실패 공통)
/// 사용처: 이미지 압축(메모리), 주소 조회(네트워크)
class ConcurrencyLimiter {
  ConcurrencyLimiter({required this.maximumConcurrentCount}) {
    if (maximumConcurrentCount <= 0) {
      throw ArgumentError.value(maximumConcurrentCount, 'maximumConcurrentCount', 'must be positive');
    }
  }

  final int maximumConcurrentCount;

  int _runningCount = 0;
  final Queue<Completer<void>> _waitingSlots = Queue<Completer<void>>();

  /// 실행 중 작업 수
  int get runningCount => _runningCount;

  /// 슬롯 대기 중 작업 수
  int get waitingCount => _waitingSlots.length;

  /// 슬롯 확보 > 작업 실행 > 슬롯 반환 (작업 결과·예외 그대로 전달)
  Future<T> run<T>(FutureOr<T> Function() task) async {
    await _acquireSlot();
    try {
      return await task();
    } finally {
      _releaseSlot();
    }
  }

  /// 빈 슬롯 있으면 즉시, 없으면 대기열 끝에서 대기
  Future<void> _acquireSlot() {
    if (_runningCount < maximumConcurrentCount) {
      _runningCount++;
      return Future<void>.value();
    }
    final waitingSlot = Completer<void>();
    _waitingSlots.add(waitingSlot);
    return waitingSlot.future;
  }

  /// 대기 작업 있으면 슬롯을 그대로 넘김 (실행 수 유지), 없으면 실행 수 감소
  void _releaseSlot() {
    if (_waitingSlots.isNotEmpty) {
      _waitingSlots.removeFirst().complete();
      return;
    }
    _runningCount--;
  }
}
