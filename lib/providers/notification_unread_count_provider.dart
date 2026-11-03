import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/providers/notification_repository_provider.dart';
import 'package:romrom_fe/repositories/notification_repository.dart';

/// 미확인 알림 수 단일 소유 provider (홈 알림 배지, 알림 목록 20건 조회 없이 개수만)
/// 알림 목록 provider도 미확인 수는 이 provider로 조회 > 전체 읽음 후 배지 함께 갱신
final notificationUnreadCountProvider = AsyncNotifierProvider<NotificationUnreadCountNotifier, int>(
  NotificationUnreadCountNotifier.new,
);

/// 미확인 알림 수: 첫 조회, 재조회 (실패 시 기존 값 유지)
class NotificationUnreadCountNotifier extends AsyncNotifier<int> {
  NotificationRepository get _repository => ref.read(notificationRepositoryProvider);

  // 재조회 순번 (늦게 끝난 이전 응답이 최신 값을 덮지 않도록)
  int _refreshSequence = 0;

  @override
  Future<int> build() {
    _refreshSequence++;
    return _repository.getUnreadCount();
  }

  /// 재조회 > 미확인 수 반환 (첫 조회 진행 중이면 그 결과 공유, 실패는 기존 값 유지 + null)
  Future<int?> refresh() async {
    try {
      if (state.isLoading && !state.hasValue) return await future;
      final refreshSequence = ++_refreshSequence;
      final unreadCount = await _repository.getUnreadCount();
      if (refreshSequence == _refreshSequence) state = AsyncData(unreadCount);
      return unreadCount;
    } catch (error) {
      debugPrint('[notification unread count] refresh failed : $error');
      return null;
    }
  }
}
