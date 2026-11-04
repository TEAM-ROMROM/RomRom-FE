import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/notification_setting_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/providers/notification_permission_prompt_service_provider.dart';
import 'package:romrom_fe/providers/notification_setting_provider.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';

/// 알림 권한 1회 안내 (교환 요청·물품 등록 성공 직후): 안내 필요 > 이유 모달 > 알림 켜기 > 시스템 권한 창
/// 허용 > FCM 토큰 등록 + 안내 문구의 교환·채팅 알림 설정 켜기, 나중에·거부 > 그대로 종료 (재안내 없음)
Future<void> showNotificationPermissionPromptOnce(BuildContext context, WidgetRef ref) async {
  final promptService = ref.read(notificationPermissionPromptServiceProvider);
  if (!await promptService.tryStartPrompt()) return;
  try {
    if (!context.mounted) return;
    final isAccepted = await CommonModal.confirm(
      context: context,
      message: '교환 요청과 채팅 답장을\n바로 받으려면 알림을 켜 주세요.',
      cancelText: '나중에',
      confirmText: '알림 켜기',
      icon: AppIcons.information,
      iconColor: AppColors.primaryYellow,
      confirmButtonColor: AppColors.primaryYellow,
      confirmTextColor: AppColors.textColorBlack,
      onCancel: () => Navigator.of(context).pop(false),
      onConfirm: () => Navigator.of(context).pop(true),
    );
    if (isAccepted != true) return;

    // await 이후 ref 사용 방지 (notifier 선확보)
    final notificationSettingNotifier = ref.read(notificationSettingProvider.notifier);
    final isGranted = await promptService.requestPermissionAndRegisterToken();
    if (!isGranted) return;
    // 권한 미결정 중 서버 설정이 꺼졌을 수 있음 > 안내한 교환·채팅 알림만 켜기 (마케팅 등 제외)
    await notificationSettingNotifier.setAll({
      NotificationSettingType.transaction: true,
      NotificationSettingType.chat: true,
    }, isSilent: true);
  } finally {
    // (성공·실패 공통)
    promptService.finishPrompt();
  }
}
