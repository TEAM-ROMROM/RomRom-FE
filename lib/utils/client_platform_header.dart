// 서버 기기 판별용 앱 플랫폼 헤더 (#949): 앱 UA(Dart)에 OS가 없어 서버(로그인 이력·대시보드)가 헤더로 판별
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:romrom_fe/models/app_urls.dart';

class ClientPlatformHeader {
  ClientPlatformHeader._();

  /// BE LoginHistoryService.CLIENT_PLATFORM_HEADER 와 같은 이름
  static const String headerName = 'X-Client-Platform';

  /// 플랫폼 > 헤더 값 (ANDROID·IOS, 그 외 null)
  static String? toHeaderValue({required bool isAndroid, required bool isIOS}) {
    if (isAndroid) return 'ANDROID';
    if (isIOS) return 'IOS';
    return null;
  }

  /// 서버 API 요청이면 헤더 추가 (외부 API 제외, 이미 있으면 유지)
  static void addTo(http.BaseRequest request, {String? apiBaseUrl}) {
    if (kIsWeb) return;
    final apiHost = Uri.tryParse(apiBaseUrl ?? AppUrls.baseUrl)?.host;
    if (apiHost == null || apiHost.isEmpty || request.url.host != apiHost) return;
    final headerValue = toHeaderValue(isAndroid: Platform.isAndroid, isIOS: Platform.isIOS);
    if (headerValue == null) return;
    request.headers.putIfAbsent(headerName, () => headerValue);
  }
}
