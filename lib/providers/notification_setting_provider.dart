/// 알림 설정(NotificationSetting) Provider (CLAUDE.md 규칙2 — optimistic 토글)
///
/// 종류: 동기 Notifier (optimistic + _inFlight dedup) — 즉시 반영 후 서버 응답으로 확정, 실패 시 prev 롤백.
/// 4-레이어 표준: lib/repositories/notification_setting_repository.dart
///               + notificationSettingRepositoryProvider(이 파일) + 이 파일.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/notification_setting_type.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/providers/member_profile_provider.dart';
import 'package:romrom_fe/repositories/notification_setting_repository.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';

final notificationSettingRepositoryProvider = Provider<NotificationSettingRepository>(
  (ref) => NotificationSettingRepository(MemberApi()),
);

final notificationSettingProvider = NotifierProvider<NotificationSettingNotifier, Map<NotificationSettingType, bool>>(
  NotificationSettingNotifier.new,
);

class NotificationSettingNotifier extends Notifier<Map<NotificationSettingType, bool>> {
  final Set<NotificationSettingType> _inFlight = {};

  bool _isSeeded = false;

  /// 세션 시작 상태 (invalidate 시 notifier 인스턴스 재사용 > 세션별 필드도 여기서 초기화)
  @override
  Map<NotificationSettingType, bool> build() {
    _isSeeded = false;
    _inFlight.clear();
    return {for (final t in NotificationSettingType.values) t: false};
  }

  /// 알림 설정 시드. force=false 일 땐 첫 시드 시점에만 적용.
  void seed(Map<NotificationSettingType, bool> values, {bool force = false}) {
    if (!force && _isSeeded) return;
    _isSeeded = true;
    state = {...state, ...values};
  }

  /// Optimistic 토글.
  Future<void> setEnabled(NotificationSettingType type, bool value) async {
    if (_inFlight.contains(type)) return;
    _inFlight.add(type);

    final prev = state[type] ?? !value;
    state = {...state, type: value};

    try {
      await ref.read(notificationSettingRepositoryProvider).update(type, value);
      _invalidateMemberProfile();
    } catch (e) {
      debugPrint('notificationSettingProvider.setEnabled 실패: $e');
      state = {...state, type: prev};
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        CommonSnackBar.show(context: ctx, message: '알림 설정 변경에 실패했어요', type: SnackBarType.error);
      }
    } finally {
      _inFlight.remove(type);
    }
  }

  /// 여러 항목 일괄 Optimistic 변경: 요청 1회 > 실패 시 전체 롤백 > 서버 확정 여부 반환
  /// (대상 중 진행 중 토글 있으면 요청 없이 false, isSilent면 실패 스낵바 생략)
  Future<bool> setAll(Map<NotificationSettingType, bool> values, {bool isSilent = false}) async {
    if (values.isEmpty) return true;
    if (values.keys.any(_inFlight.contains)) return false;
    _inFlight.addAll(values.keys);

    final prev = state;
    state = {...state, ...values};

    try {
      await ref.read(notificationSettingRepositoryProvider).updateAll(values);
      _invalidateMemberProfile();
      return true;
    } catch (e) {
      debugPrint('notificationSettingProvider.setAll 실패: $e');
      state = prev;
      final ctx = navigatorKey.currentContext;
      if (!isSilent && ctx != null) {
        CommonSnackBar.show(context: ctx, message: '알림 설정 변경에 실패했어요', type: SnackBarType.error);
      }
      return false;
    } finally {
      _inFlight.removeAll(values.keys);
    }
  }

  /// 회원 프로필의 알림 동의값 무효화 (조회된 적 있을 때만, 구독 중이면 즉시 재조회)
  void _invalidateMemberProfile() {
    if (ref.exists(memberProfileProvider)) ref.invalidate(memberProfileProvider);
  }
}
