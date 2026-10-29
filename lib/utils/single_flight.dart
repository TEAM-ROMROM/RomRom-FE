/// 비동기 작업 단일 실행: 진행 중이면 같은 Future 공유, 완료 시 비움 (성공·실패 공통)
class SingleFlight<T> {
  Future<T>? _runningFuture;

  bool get isRunning => _runningFuture != null;

  /// 실행 중 Future 있으면 반환 > 없으면 task 실행 후 완료 시 해제
  Future<T> run(Future<T> Function() task) {
    final runningFuture = _runningFuture;
    if (runningFuture != null) return runningFuture;

    late final Future<T> newFuture;
    // task 동기 throw도 Future 에러로 변환 (Future.sync)
    newFuture = Future<T>.sync(task).whenComplete(() {
      if (identical(_runningFuture, newFuture)) _runningFuture = null;
    });
    _runningFuture = newFuture;
    return newFuture;
  }
}
