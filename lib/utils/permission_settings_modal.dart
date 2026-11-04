import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';

/// 권한 꺼짐 > 설정 이동 확인 모달 (취소 / 설정 열기, 카메라·사진 저장 공통)
/// Apple 가이드라인 5.1.1(iv): 설정 앱 자동 이동 금지 > 사용자가 직접 선택
Future<void> showPermissionSettingsModal({required BuildContext context, required String message}) async {
  await CommonModal.confirm(
    context: context,
    message: message,
    cancelText: '취소',
    confirmText: '설정 열기',
    onCancel: () => Navigator.of(context).pop(),
    onConfirm: () {
      Navigator.of(context).pop();
      openAppSettings();
    },
  );
}
