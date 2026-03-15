import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:romrom_fe/enums/app_update_type.dart';
import 'package:romrom_fe/models/apis/responses/app_version_response.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/services/api_client.dart';

class AppVersionApi {
  static final AppVersionApi _instance = AppVersionApi._internal();

  factory AppVersionApi() => _instance;

  AppVersionApi._internal();

  /// 앱 버전 체크 API
  /// `GET /api/app/version`
  /// 인증 불필요 — 스플래시 단계에서 호출
  Future<AppVersionResponse?> getAppVersion() async {
    const String url = '${AppUrls.baseUrl}/api/app/version';

    try {
      final response = await ApiClient.sendHttpRequest(
        url: url,
        method: 'GET',
        isAuthRequired: false,
        onSuccess: (_) {},
      );

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

  /// Mock 응답 (백엔드 API 완성 전 사용)
  /// 실제 API 연동 후 이 메서드는 삭제한다.
  AppVersionResponse getMockAppVersion() {
    return const AppVersionResponse(
      minimumVersion: '0.0.1', // 낮게 설정 → 강제 업데이트 발동 안 함 (개발 중)
      latestVersion: '1.9.67',
      androidStoreUrl: AppUrls.androidStoreUrl,
      iosStoreUrl: AppUrls.iosStoreUrl,
    );
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
      // 실제 API 호출 시도, 실패 시 Mock 사용
      AppVersionResponse? versionInfo = await getAppVersion();
      versionInfo ??= getMockAppVersion();

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
