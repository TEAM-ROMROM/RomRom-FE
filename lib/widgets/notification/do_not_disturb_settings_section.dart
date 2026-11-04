import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/providers/do_not_disturb_setting_provider.dart';
import 'package:romrom_fe/states/do_not_disturb_setting_state.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/completed_toggle_switch.dart';
import 'package:romrom_fe/widgets/notification/do_not_disturb_time_picker_sheet.dart';

/// 알림 설정 > 방해금지 시간 그룹: 사용 스위치, 켜져 있으면 시작·종료 시각 행 (탭 > 시각 선택 시트) (#1007)
/// 상태는 doNotDisturbSettingProvider 단일 소유 (설정 화면이 서버 값으로 seed)
class DoNotDisturbSettingsSection extends ConsumerWidget {
  const DoNotDisturbSettingsSection({super.key});

  static const String _sectionTitle = '방해금지 시간';
  static const String _sectionDescription = '설정한 시간에는 푸시 알림을 보내지 않아요';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(doNotDisturbSettingProvider);
    return Container(
      decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSwitchRow(ref, setting),
          if (setting.isEnabled) ...[
            _buildTimeRow(
              label: '시작',
              timeText: setting.startTimeText,
              onTap: () => _onStartTimeTap(context, ref, setting),
            ),
            _buildTimeRow(
              label: '종료',
              timeText: setting.isOvernight ? '다음 날 ${setting.endTimeText}' : setting.endTimeText,
              onTap: () => _onEndTimeTap(context, ref, setting),
            ),
          ],
        ],
      ),
    );
  }

  /// 사용 스위치 행 (제목·설명 + 스위치, 권한 확인 불필요 — 푸시를 줄이는 설정)
  Widget _buildSwitchRow(WidgetRef ref, DoNotDisturbSettingState setting) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 4.w, top: 14, bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_sectionTitle, style: CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite)),
                const SizedBox(height: 8),
                Text(
                  _sectionDescription,
                  style: CustomTextStyles.p3.copyWith(color: AppColors.opacity60White, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          CompletedToggleSwitch(
            value: setting.isEnabled,
            semanticLabel: _sectionTitle,
            touchAreaPadding: EdgeInsets.fromLTRB(8.w, 12, 12.w, 12),
            onChanged: (isEnabled) =>
                ref.read(doNotDisturbSettingProvider.notifier).save(setting.copyWith(isEnabled: isEnabled)),
          ),
        ],
      ),
    );
  }

  /// 시각 행 (라벨 + 시각, 탭 > 시각 선택, 터치 높이 44px 이상)
  Widget _buildTimeRow({required String label, required String timeText, required VoidCallback onTap}) {
    return AppPressable(
      onTap: onTap,
      scaleDown: AppPressable.scaleCard,
      enableRipple: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: CustomTextStyles.p2.copyWith(color: AppColors.textColorWhite)),
            ),
            Text(
              timeText,
              style: CustomTextStyles.p2.copyWith(color: AppColors.primaryYellow, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  /// 시작 시각 선택 > 저장 (종료와 같으면 저장 막고 안내)
  Future<void> _onStartTimeTap(BuildContext context, WidgetRef ref, DoNotDisturbSettingState setting) async {
    final selectedTime = await DoNotDisturbTimePickerSheet.show(
      context: context,
      title: '방해금지 시작 시간',
      initialTime: setting.startTime,
    );
    if (selectedTime == null || !context.mounted) return;
    await _saveIfValid(context, ref, setting.copyWith(startTime: selectedTime));
  }

  /// 종료 시각 선택 > 저장 (시작과 같으면 저장 막고 안내)
  Future<void> _onEndTimeTap(BuildContext context, WidgetRef ref, DoNotDisturbSettingState setting) async {
    final selectedTime = await DoNotDisturbTimePickerSheet.show(
      context: context,
      title: '방해금지 종료 시간',
      initialTime: setting.endTime,
    );
    if (selectedTime == null || !context.mounted) return;
    await _saveIfValid(context, ref, setting.copyWith(endTime: selectedTime));
  }

  /// 시작 = 종료 > 안내만, 그 외 > provider 저장 (실패 안내는 provider 담당)
  Future<void> _saveIfValid(BuildContext context, WidgetRef ref, DoNotDisturbSettingState nextSetting) async {
    if (nextSetting.hasSameStartAndEnd) {
      CommonSnackBar.show(context: context, message: '시작과 종료 시간을 다르게 설정해 주세요', type: SnackBarType.error);
      return;
    }
    await ref.read(doNotDisturbSettingProvider.notifier).save(nextSetting);
  }
}
