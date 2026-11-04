import 'package:romrom_fe/enums/app_update_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 복귀 버전 확인: 확인 주기(24시간) 판정, 서버 응답 받은 경우만 확인 시각 저장
/// 조회 실패·제한 시간 초과 > 시각 저장 안 함 (다음 복귀 때 재확인)
class ResumeVersionCheckService {
  // SharedPreferences: 마지막 버전 확인 성공 시각 (epoch ms)
  static const String _lastCheckedAtKey = 'last_version_check_timestamp';
  // 복귀 확인 재실행 간격
  static const Duration checkInterval = Duration(hours: 24);

  final Future<UpdateType?> Function() _fetchServerUpdateType;
  final DateTime Function() _now;

  // 확인 진행 중 (짧은 간격 연속 복귀 시 중복 요청 차단)
  bool _isChecking = false;

  ResumeVersionCheckService({required Future<UpdateType?> Function() fetchServerUpdateType, DateTime Function()? now})
    : _fetchServerUpdateType = fetchServerUpdateType,
      _now = now ?? DateTime.now;

  /// 주기 경과 시 서버 확인 > 업데이트 타입 (주기 미경과·진행 중·실패 시 none)
  Future<UpdateType> checkIfDue() async {
    if (_isChecking) return UpdateType.none;
    _isChecking = true;
    try {
      final preferences = await SharedPreferences.getInstance();
      final lastCheckedAtMilliseconds = preferences.getInt(_lastCheckedAtKey) ?? 0;
      final lastCheckedAt = DateTime.fromMillisecondsSinceEpoch(lastCheckedAtMilliseconds);
      if (_now().difference(lastCheckedAt) < checkInterval) return UpdateType.none;

      final updateType = await _fetchServerUpdateType();
      if (updateType == null) return UpdateType.none;

      await preferences.setInt(_lastCheckedAtKey, _now().millisecondsSinceEpoch);
      return updateType;
    } finally {
      // (성공·실패 공통)
      _isChecking = false;
    }
  }
}
