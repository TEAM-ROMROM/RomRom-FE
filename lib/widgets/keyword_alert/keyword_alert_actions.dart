import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/apis/objects/keyword_alert.dart';
import 'package:romrom_fe/providers/keyword_alerts_provider.dart';
import 'package:romrom_fe/states/keyword_alerts_state.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/utils/keyword_alert_rules.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/notification_permission_prompt_modal.dart';

// 키워드 등록 후 알림 권한 안내 문구 (허용 시 켤 설정 없음: 키워드 등록 = 수신 동의)
const String keywordAlertPermissionPromptMessage = '등록한 키워드의 새 물품 소식을\n바로 받으려면 알림을 켜 주세요.';

/// 키워드 등록 공통 (설정 화면·검색 종 버튼): 입력 검사 > 서버 등록 > 성공 안내 > 알림 권한 1회 안내
/// 검사 거부·서버 거부 > 사유 스낵바, 등록 성공 여부 반환 (권한 거부와 무관하게 등록 유지)
Future<bool> registerKeywordAlertWithFeedback({
  required BuildContext context,
  required WidgetRef ref,
  required String keyword,
  // 등록 직후·권한 안내 전 호출 (입력칸 비우기 등, 화면이 열려 있을 때만)
  VoidCallback? onRegistered,
}) async {
  final keywordAlertsNotifier = ref.read(keywordAlertsProvider.notifier);
  final currentState = ref.read(keywordAlertsProvider).valueOrNull ?? const KeywordAlertsState();

  // 앱 검사 (길이, 중복, 개수: 목록 불러오기 전이면 서버 검사에 맡김)
  final rejectionReason = findKeywordAlertRejectionReason(
    keyword: keyword,
    registeredKeywords: currentState.registeredKeywords,
    maximumKeywordAlertCount: currentState.maximumKeywordAlertCount,
  );
  if (rejectionReason != null) {
    CommonSnackBar.show(
      context: context,
      message: rejectionReason.buildMessage(maximumKeywordAlertCount: currentState.maximumKeywordAlertCount),
      type: SnackBarType.info,
    );
    return false;
  }

  final tidiedKeyword = tidyKeywordAlert(keyword);
  try {
    await keywordAlertsNotifier.register(tidiedKeyword);
  } catch (error) {
    debugPrint('[keyword alert] register failed : $error');
    if (context.mounted) {
      CommonSnackBar.show(
        context: context,
        message: ErrorUtils.getServerProvidedErrorMessage(error),
        type: SnackBarType.error,
      );
    }
    return false;
  }

  // 화면이 닫혔으면 후속 처리 없음 (등록은 유지)
  if (!context.mounted) return true;
  onRegistered?.call();
  CommonSnackBar.show(context: context, message: "'$tidiedKeyword' 키워드 알림을 등록했어요");
  await showNotificationPermissionPromptOnce(
    context,
    ref,
    message: keywordAlertPermissionPromptMessage,
    settingTypesToEnableOnGrant: const {},
  );
  return true;
}

/// 키워드 삭제 공통: 서버 삭제 > 해제 안내 / 실패 > 사유 스낵바 (삭제 성공 여부 반환)
Future<bool> deleteKeywordAlertWithFeedback({
  required BuildContext context,
  required WidgetRef ref,
  required KeywordAlert keywordAlert,
}) async {
  final keywordAlertId = keywordAlert.keywordAlertId;
  if (keywordAlertId == null) return false;
  try {
    await ref.read(keywordAlertsProvider.notifier).delete(keywordAlertId);
  } catch (error) {
    debugPrint('[keyword alert] delete failed : $error');
    if (context.mounted) {
      CommonSnackBar.show(
        context: context,
        message: ErrorUtils.getServerProvidedErrorMessage(error),
        type: SnackBarType.error,
      );
    }
    return false;
  }
  if (context.mounted) {
    CommonSnackBar.show(context: context, message: "'${keywordAlert.keyword ?? ''}' 키워드 알림을 해제했어요");
  }
  return true;
}
