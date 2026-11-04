import 'package:flutter/foundation.dart';

/// 강제 업데이트 잠금: 강제 업데이트 화면 표시 여부 단일 원본 (딥링크·세션 종료 화면 이동 차단 기준)
/// 한 번 잠그면 앱 프로세스 종료까지 유지 (업데이트 설치 > 재실행으로만 해제)
class ForcedUpdateLock {
  ForcedUpdateLock();

  // 앱 전체 공용 인스턴스 (테스트는 resetForTest로 초기화)
  static final ForcedUpdateLock instance = ForcedUpdateLock();

  bool _isForcedUpdateShowing = false;

  bool get isForcedUpdateShowing => _isForcedUpdateShowing;

  /// 강제 업데이트 화면 표시 직전 호출
  void lock() => _isForcedUpdateShowing = true;

  @visibleForTesting
  void resetForTest() => _isForcedUpdateShowing = false;
}
