import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';

/// 카메라 권한을 확보한다.
///
/// - 허용되면 true.
/// - 거부되면 안내 스낵바를 띄우고 false.
/// - 영구 거부(다시 묻지 않음)면 안내 스낵바 + 설정 화면 이동 후 false.
///
/// 호출 측은 반환값이 false면 촬영을 진행하지 않는다.
Future<bool> ensureCameraPermission(BuildContext context) async {
  final status = await Permission.camera.status;

  if (status.isGranted || status.isLimited) {
    return true;
  }

  if (status.isPermanentlyDenied) {
    if (context.mounted) {
      CommonSnackBar.show(context: context, message: '카메라 권한이 꺼져 있어요. 설정에서 권한을 허용해주세요.', type: SnackBarType.info);
    }
    await openAppSettings();
    return false;
  }

  final result = await Permission.camera.request();
  if (result.isGranted || result.isLimited) {
    return true;
  }

  if (context.mounted) {
    if (result.isPermanentlyDenied) {
      CommonSnackBar.show(context: context, message: '카메라 권한이 꺼져 있어요. 설정에서 권한을 허용해주세요.', type: SnackBarType.info);
      await openAppSettings();
    } else {
      CommonSnackBar.show(context: context, message: '카메라 권한이 필요해요.', type: SnackBarType.info);
    }
  }
  return false;
}
