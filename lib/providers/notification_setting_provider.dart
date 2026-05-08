import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/notification_setting_type.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
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

  bool _seeded = false;

  @override
  Map<NotificationSettingType, bool> build() => {for (final t in NotificationSettingType.values) t: false};

  /// 알림 설정 시드. force=false 일 땐 첫 시드 시점에만 적용.
  void seed(Map<NotificationSettingType, bool> values, {bool force = false}) {
    if (!force && _seeded) return;
    _seeded = true;
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
}
