import 'dart:io';

import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

/// 스토어 롬롬 페이지 열기 > 성공 여부 (실패 시 스토어 직접 검색 안내 스낵바)
Future<bool> openAppStorePage(BuildContext context) async {
  final storeUrl = Platform.isAndroid ? AppUrls.androidStoreUrl : AppUrls.iosStoreUrl;
  var isOpened = false;
  try {
    isOpened = await launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication);
  } catch (error) {
    debugPrint('[app store] open failed : $error');
  }
  if (!isOpened && context.mounted) {
    final storeName = Platform.isAndroid ? 'Play 스토어' : 'App Store';
    CommonSnackBar.show(
      context: context,
      message: '스토어를 열지 못했어요. $storeName에서 \'롬롬\'을 검색해 업데이트해 주세요.',
      type: SnackBarType.error,
    );
  }
  return isOpened;
}
