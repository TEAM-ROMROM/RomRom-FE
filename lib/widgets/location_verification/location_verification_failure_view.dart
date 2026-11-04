import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/location_verification_failure.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';

/// 동네 인증 실패 안내: 사유 문구 + 다시 시도·설정 열기 (권한 영구 거부 등 > 설정 열기가 주 버튼)
class LocationVerificationFailureView extends StatelessWidget {
  final LocationVerificationFailure failure;
  final VoidCallback onRetryPressed;
  final VoidCallback onOpenSettingsPressed;

  const LocationVerificationFailureView({
    super.key,
    required this.failure,
    required this.onRetryPressed,
    required this.onOpenSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasSettingsAction = failure.settingsDestination != null;
    final isSettingsPrimary = hasSettingsAction && failure.isSettingsPrimaryAction;
    return EmptyStateView(
      icon: AppIcons.location,
      centerText: failure.title,
      descriptionText: failure.description,
      buttonText: isSettingsPrimary ? '설정 열기' : '다시 시도',
      onButtonTap: isSettingsPrimary ? onOpenSettingsPressed : onRetryPressed,
      secondaryButtonText: hasSettingsAction ? (isSettingsPrimary ? '다시 시도' : '설정 열기') : null,
      onSecondaryButtonTap: hasSettingsAction ? (isSettingsPrimary ? onRetryPressed : onOpenSettingsPressed) : null,
    );
  }
}
