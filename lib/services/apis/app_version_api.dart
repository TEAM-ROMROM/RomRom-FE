import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:romrom_fe/enums/app_update_type.dart';
import 'package:romrom_fe/models/apis/responses/app_version_response.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/utils/log_http_client_interceptor.dart';
import 'package:romrom_fe/utils/secured_api_utils.dart';

class AppVersionApi {
  static final AppVersionApi _instance = AppVersionApi._internal();

  factory AppVersionApi() => _instance;

  AppVersionApi._internal();

  static final LoggingHttpClient _client = LoggingHttpClient(http.Client());

  /// 앱 버전 체크 API
  /// `POST /api/app/version/check`
  /// @SecuredApi (HMAC + Timestamp) 인증, JWT 불필요
  Future<AppVersionResponse?> getAppVersion() async {
    const String url = '${AppUrls.baseUrl}/api/app/version/check';

    try {
      final securedHeaders = SecuredApiUtils.generateHeaders();

      final response = await _client.post(Uri.parse(url), headers: securedHeaders);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return AppVersionResponse.fromJson(json);
      }
      return null;
    } catch (e) {
      debugPrint('[AppVersionApi] 버전 체크 API 호출 실패: $e');
      return null;
    }
  }

  /// 현재 앱 버전을 가져온다
  Future<String> getCurrentAppVersion() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    return info.version; // e.g. "1.9.67"
  }

  /// 버전 문자열 비교: current < minimum 이면 true
  /// "1.9.0" < "1.9.67" → true
  bool isVersionLower(String current, String minimum) {
    final List<int> currentParts = current.split('.').map(int.parse).toList();
    final List<int> minimumParts = minimum.split('.').map(int.parse).toList();

    // 길이 맞춤 (짧은 쪽에 0 패딩)
    while (currentParts.length < minimumParts.length) {
      currentParts.add(0);
    }
    while (minimumParts.length < currentParts.length) {
      minimumParts.add(0);
    }

    for (int i = 0; i < currentParts.length; i++) {
      if (currentParts[i] < minimumParts[i]) return true;
      if (currentParts[i] > minimumParts[i]) return false;
    }
    return false; // 같으면 false (업데이트 불필요)
  }

  /// 업데이트 타입 결정
  Future<UpdateType> checkUpdateType() async {
    try {
      final AppVersionResponse? versionInfo = await getAppVersion();
      if (versionInfo == null) return UpdateType.none; // API 실패 시 차단하지 않음

      final String currentVersion = await getCurrentAppVersion();
      debugPrint('[AppVersionApi] 현재 버전: $currentVersion, 최소 버전: ${versionInfo.minimumVersion}');

      if (isVersionLower(currentVersion, versionInfo.minimumVersion)) {
        return UpdateType.force;
      }
      return UpdateType.none;
    } catch (e) {
      debugPrint('[AppVersionApi] 버전 체크 실패, 정상 진행: $e');
      return UpdateType.none; // 실패 시 차단하지 않음
    }
  }
}
