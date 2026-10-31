import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';

/// 카메라 권한을 확보한다.
///
/// - 허용되면 true.
/// - 거부되면 안내 스낵바를 띄우고 false.
/// - 영구 거부(다시 묻지 않음)면 설정 이동 확인 모달을 띄우고 false.
///
/// 호출 측은 반환값이 false면 촬영을 진행하지 않는다.
Future<bool> ensureCameraPermission(BuildContext context) async {
  final status = await Permission.camera.status;

  if (status.isGranted || status.isLimited) {
    return true;
  }

  if (status.isPermanentlyDenied) {
    if (context.mounted) {
      await _showCameraSettingsModal(context);
    }
    return false;
  }

  final result = await Permission.camera.request();
  if (result.isGranted || result.isLimited) {
    return true;
  }

  if (context.mounted) {
    if (result.isPermanentlyDenied) {
      await _showCameraSettingsModal(context);
    } else {
      CommonSnackBar.show(context: context, message: '카메라 권한이 필요해요.', type: SnackBarType.info);
    }
  }
  return false;
}

/// 카메라 권한이 영구 거부된 경우 설정 이동 여부를 묻는 모달.
///
/// Apple 가이드라인(5.1.1(iv))에 따라 설정 앱으로 자동 이동하지 않고
/// 사용자가 직접 선택하도록 한다.
Future<void> _showCameraSettingsModal(BuildContext context) async {
  await CommonModal.confirm(
    context: context,
    message: '카메라 권한이 꺼져 있어요.\n사진 촬영을 위해 설정에서\n카메라 접근을 허용해주세요.',
    cancelText: '취소',
    confirmText: '설정 열기',
    onCancel: () => Navigator.of(context).pop(),
    onConfirm: () {
      Navigator.of(context).pop();
      openAppSettings();
    },
  );
}
