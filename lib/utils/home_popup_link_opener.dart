import 'package:flutter/material.dart';
import 'package:romrom_fe/utils/deep_link_router.dart';
import 'package:url_launcher/url_launcher.dart';

// 앱 내부 딥링크 스킴 (romrom://item/detail?itemId=...)
const String romromDeepLinkScheme = 'romrom';
// 외부 브라우저로 여는 스킴 2개
const Set<String> externalBrowserSchemes = {'http', 'https'};

/// 홈 팝업 링크 이동 함수 형태 (테스트에서 대역 주입)
typedef HomePopupLinkOpener = Future<void> Function(BuildContext context, String linkUrl);

/// 이동 가능한 링크: romrom:// 또는 http(s)://, 호스트 있음
bool isOpenableHomePopupLink(String? linkUrl) {
  final uri = linkUrl == null ? null : Uri.tryParse(linkUrl);
  if (uri == null || uri.host.isEmpty) return false;
  return uri.scheme == romromDeepLinkScheme || externalBrowserSchemes.contains(uri.scheme);
}

/// 홈 팝업 링크 열기: romrom:// > 앱 내 딥링크 라우터, http(s):// > 외부 브라우저, 그 외 무시
Future<void> openHomePopupLink(BuildContext context, String linkUrl) async {
  if (!isOpenableHomePopupLink(linkUrl)) return;
  final uri = Uri.parse(linkUrl);
  try {
    if (uri.scheme == romromDeepLinkScheme) {
      await RomRomDeepLinkRouter.openFromUri(context, uri);
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (error) {
    debugPrint('[home popup] link open failed : $error');
  }
}
