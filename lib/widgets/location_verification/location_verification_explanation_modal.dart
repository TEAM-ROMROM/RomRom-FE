import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/location_verification_purpose.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';

// 위치 사용 이유 (시스템 권한 창 전 앱 안내, 모든 진입점 공통)
const String locationVerificationReasonText = '이웃끼리만 거래할 수 있도록\n지금 있는 위치로 동네를 확인해요.\n위치는 동네 확인에만 사용해요.';

/// 동네 인증 안내 모달 (시스템 권한 창보다 먼저): 위치 인증하기 > true, 나중에 > false
Future<bool> showLocationVerificationExplanation(BuildContext context, {LocationVerificationPurpose? purpose}) async {
  final purposeText = purpose == null ? '동네 인증이 필요해요.' : '${purpose.actionPhrase}\n동네 인증이 필요해요.';
  final isAccepted = await CommonModal.confirm(
    context: context,
    message: '$purposeText\n\n$locationVerificationReasonText',
    cancelText: '나중에',
    confirmText: '위치 인증하기',
    icon: AppIcons.location,
    iconColor: AppColors.primaryYellow,
    confirmButtonColor: AppColors.primaryYellow,
    confirmTextColor: AppColors.textColorBlack,
    onCancel: () => Navigator.of(context).pop(false),
    onConfirm: () => Navigator.of(context).pop(true),
  );
  return isAccepted == true;
}
