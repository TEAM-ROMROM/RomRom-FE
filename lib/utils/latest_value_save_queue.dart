// 최신 값 직렬 저장: 저장 요청이 겹치면 진행 중 요청 뒤에 마지막 값만 저장 (응답 순서 꼬임·서버 <-> 화면 불일치 방지)

/// 직렬 저장 결과: 마지막 성공 값, 마지막 시도 실패 여부·원인 (false 응답이면 원인 null)
class LatestValueSaveResult<T> {
  final T? lastSavedValue;
  final bool isLatestSaveFailed;
  final Object? latestSaveError;

  const LatestValueSaveResult({required this.lastSavedValue, required this.isLatestSaveFailed, this.latestSaveError});
}

/// 최신 값 저장 대기열: 저장 중 들어온 값은 마지막 1개만 보관 > 진행 중 저장 뒤 이어서 저장
class LatestValueSaveQueue<T> {
  // 값 1개 저장 (성공 true, 실패 false 또는 예외)
  final Future<bool> Function(T value) saveValue;

  LatestValueSaveQueue({required this.saveValue});

  bool _isSaving = false;
  bool _hasQueuedValue = false;
  T? _queuedValue;

  /// 저장 요청: 진행 중이면 대기열에 넣고 null, 아니면 대기열이 빌 때까지 저장 후 결과 반환
  Future<LatestValueSaveResult<T>?> save(T value) async {
    if (_isSaving) {
      _queuedValue = value;
      _hasQueuedValue = true;
      return null;
    }

    _isSaving = true;
    T? lastSavedValue;
    var isLatestSaveFailed = false;
    Object? latestSaveError;
    try {
      var valueToSave = value;
      while (true) {
        latestSaveError = null;
        try {
          isLatestSaveFailed = !await saveValue(valueToSave);
        } catch (error) {
          isLatestSaveFailed = true;
          latestSaveError = error;
        }
        if (!isLatestSaveFailed) lastSavedValue = valueToSave;

        if (!_hasQueuedValue) break;
        valueToSave = _queuedValue as T;
        _hasQueuedValue = false;
        _queuedValue = null;
      }
    } finally {
      // (성공·실패 공통)
      _isSaving = false;
    }
    return LatestValueSaveResult(
      lastSavedValue: lastSavedValue,
      isLatestSaveFailed: isLatestSaveFailed,
      latestSaveError: latestSaveError,
    );
  }
}
