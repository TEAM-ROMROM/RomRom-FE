import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

/// 고객 문의 메일 작성 화면 열기 (메일 앱 없음·실패 시 문의 주소 안내 스낵바)
Future<void> launchSupportEmail(BuildContext context, {required String subject}) async {
  final mailUri = Uri(scheme: 'mailto', path: AppUrls.supportEmailAddress, queryParameters: {'subject': subject});
  var isLaunched = false;
  try {
    isLaunched = await canLaunchUrl(mailUri) && await launchUrl(mailUri);
  } catch (error) {
    debugPrint('[support email] launch failed : $error');
  }
  if (!isLaunched && context.mounted) {
    CommonSnackBar.show(
      context: context,
      message: '메일 앱이 없습니다. ${AppUrls.supportEmailAddress} 으로 문의해 주세요.',
      type: SnackBarType.info,
    );
  }
}
