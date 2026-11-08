import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/repositories/keyword_alert_repository.dart';
import 'package:romrom_fe/services/apis/keyword_alert_api.dart';
import 'package:romrom_fe/states/keyword_alerts_state.dart';

/// KeywordAlertRepository 주입 (테스트 override)
final keywordAlertRepositoryProvider = Provider<KeywordAlertRepository>(
  (ref) => KeywordAlertRepository(KeywordAlertApi()),
);

/// 키워드 알림 목록 단일 소유 provider (알림 설정·키워드 알림 설정·검색 화면 구독, #1020)
final keywordAlertsProvider = AsyncNotifierProvider<KeywordAlertsNotifier, KeywordAlertsState>(
  KeywordAlertsNotifier.new,
);

/// 키워드 알림: 목록 조회, 다시 조회, 등록, 삭제
/// 등록·삭제 응답 = 서버 최신 목록 > 그대로 상태 반영 (실패 > 이전 상태 유지 + 예외 전달)
class KeywordAlertsNotifier extends AsyncNotifier<KeywordAlertsState> {
  KeywordAlertRepository get _repository => ref.read(keywordAlertRepositoryProvider);

  @override
  Future<KeywordAlertsState> build() => _fetch();

  Future<KeywordAlertsState> _fetch() async => KeywordAlertsState.fromResponse(await _repository.getKeywordAlerts());

  /// 서버 재조회 (첫 로드 중 > 무시, 실패 > 이전 데이터 유지)
  Future<void> reload() async {
    if (state.isLoading) return;
    final next = await AsyncValue.guard(_fetch);
    if (next.hasError) debugPrint('[keyword alert] reload failed : ${next.error}');
    state = next.hasError ? next.copyWithPrevious(state) : next;
  }

  /// 키워드 등록 > 응답 목록 반영 (거부·실패 > 상태 유지, 예외 전달)
  Future<void> register(String keyword) async {
    final response = await _repository.registerKeywordAlert(keyword);
    state = AsyncData(KeywordAlertsState.fromResponse(response));
  }

  /// 키워드 삭제 > 응답 목록 반영 (실패 > 상태 유지, 예외 전달)
  Future<void> delete(String keywordAlertId) async {
    final response = await _repository.deleteKeywordAlert(keywordAlertId);
    state = AsyncData(KeywordAlertsState.fromResponse(response));
  }
}
