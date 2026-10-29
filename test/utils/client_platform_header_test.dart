import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:romrom_fe/utils/client_platform_header.dart';

/// 앱 플랫폼 헤더 (#949): 값 변환, 서버 API 요청에만 추가, 기존 값 유지
void main() {
  const apiBaseUrl = 'https://api.romrom.suhsaechan.kr';

  test('플랫폼 > 헤더 값: ANDROID·IOS, 그 외 null', () {
    expect(ClientPlatformHeader.toHeaderValue(isAndroid: true, isIOS: false), 'ANDROID');
    expect(ClientPlatformHeader.toHeaderValue(isAndroid: false, isIOS: true), 'IOS');
    expect(ClientPlatformHeader.toHeaderValue(isAndroid: false, isIOS: false), isNull);
  });

  test('외부 API 요청에는 헤더를 붙이지 않음', () {
    final externalRequest = http.Request('GET', Uri.parse('https://maps.apigw.ntruss.com/map-static/v2/raster'));
    ClientPlatformHeader.addTo(externalRequest, apiBaseUrl: apiBaseUrl);
    expect(externalRequest.headers.containsKey(ClientPlatformHeader.headerName), isFalse);
  });

  test('서버 API 요청: 모바일이면 헤더 추가, 이미 있으면 유지', () {
    final apiRequest = http.Request('POST', Uri.parse('$apiBaseUrl/api/auth/login'));
    ClientPlatformHeader.addTo(apiRequest, apiBaseUrl: apiBaseUrl);
    final expectedValue = ClientPlatformHeader.toHeaderValue(isAndroid: Platform.isAndroid, isIOS: Platform.isIOS);
    expect(apiRequest.headers[ClientPlatformHeader.headerName], expectedValue);

    final presetRequest = http.Request('POST', Uri.parse('$apiBaseUrl/api/auth/login'))
      ..headers[ClientPlatformHeader.headerName] = 'IOS';
    ClientPlatformHeader.addTo(presetRequest, apiBaseUrl: apiBaseUrl);
    expect(presetRequest.headers[ClientPlatformHeader.headerName], 'IOS');
  });
}
