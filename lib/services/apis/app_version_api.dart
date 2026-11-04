import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:romrom_fe/enums/app_update_type.dart';
import 'package:romrom_fe/models/apis/responses/app_version_response.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/utils/app_version_comparison.dart';
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
    final String url = '${AppUrls.baseUrl}/api/app/version/check';

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

  /// 업데이트 타입 판정: 서버 버전 조회 > 현재 버전 비교 (조회·설치 버전 확인 실패 시 null)
  Future<UpdateType?> fetchUpdateType() async {
    try {
      final AppVersionResponse? versionInfo = await getAppVersion();
      if (versionInfo == null) return null;

      final String currentVersion = await getCurrentAppVersion();
      debugPrint(
        '[AppVersionApi] 현재 버전: $currentVersion, 최소 버전: ${versionInfo.minimumVersion}, 최신 버전: ${versionInfo.latestVersion}',
      );
      return resolveUpdateType(
        currentVersion: currentVersion,
        minimumVersion: versionInfo.minimumVersion,
        latestVersion: versionInfo.latestVersion,
      );
    } catch (error) {
      debugPrint('[app version] check failed : $error');
      return null;
    }
  }
}
