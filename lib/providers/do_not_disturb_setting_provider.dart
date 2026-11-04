/// 방해금지 시간 설정 Provider (CLAUDE.md 규칙2 — optimistic 토글, #1007)
///
/// 종류: 동기 Notifier (optimistic + 진행 중 중복 요청 무시) — 즉시 반영 후 서버 응답으로 확정, 실패 시 이전 값 롤백.
/// 4-레이어: NotificationSettingRepository.updateDoNotDisturb > DoNotDisturbSettingState > 이 파일.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/providers/member_profile_provider.dart';
import 'package:romrom_fe/providers/notification_setting_provider.dart';
import 'package:romrom_fe/states/do_not_disturb_setting_state.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';

final doNotDisturbSettingProvider = NotifierProvider<DoNotDisturbSettingNotifier, DoNotDisturbSettingState>(
  DoNotDisturbSettingNotifier.new,
);

class DoNotDisturbSettingNotifier extends Notifier<DoNotDisturbSettingState> {
  bool _isUpdating = false;

  /// 세션 시작 상태 (invalidate 시 notifier 인스턴스 재사용 > 세션별 필드도 여기서 초기화)
  @override
  DoNotDisturbSettingState build() {
    _isUpdating = false;
    return const DoNotDisturbSettingState();
  }

  /// 서버 값으로 덮어쓰기 (설정 화면 진입 시 회원 정보 기준, 저장 중이면 무시)
  void seed(DoNotDisturbSettingState setting) {
    if (_isUpdating) return;
    state = setting;
  }

  /// Optimistic 저장 > 서버 확정 여부 반환 (진행 중·같은 값·시작=종료 > 요청 없이 false)
  Future<bool> save(DoNotDisturbSettingState nextSetting) async {
    if (_isUpdating || nextSetting == state || nextSetting.hasSameStartAndEnd) return false;
    _isUpdating = true;

    final previousSetting = state;
    state = nextSetting;

    try {
      await ref.read(notificationSettingRepositoryProvider).updateDoNotDisturb(nextSetting);
      if (ref.exists(memberProfileProvider)) ref.invalidate(memberProfileProvider);
      return true;
    } catch (error) {
      debugPrint('doNotDisturbSettingProvider.save 실패: $error');
      state = previousSetting;
      final navigatorContext = navigatorKey.currentContext;
      if (navigatorContext != null) {
        CommonSnackBar.show(context: navigatorContext, message: '방해금지 시간 변경에 실패했어요', type: SnackBarType.error);
      }
      return false;
    } finally {
      _isUpdating = false;
    }
  }
}
