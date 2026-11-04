import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/app_update_type.dart';
import 'package:romrom_fe/services/apis/app_version_api.dart';
import 'package:romrom_fe/utils/app_build_type.dart';

/// 앱 버전 저장소: 업데이트 필요 여부 판정 (AppVersionApi 래핑, UI 모름)
/// 판정 제한 시간 초과 > 실패 처리 (느린 버전 API가 스플래시 전체 제한 시간을 다 쓰지 않게)
class AppVersionRepository {
  // 버전 확인 제한 시간 (5초, HTTP 기본 15초보다 짧게)
  static const Duration versionCheckTimeout = Duration(seconds: 5);

  final AppVersionApi _api;
  final Duration _checkTimeout;
  // 테스트 빌드 > 버전 확인 생략 (#996)
  final bool _isUpdateCheckSkipped;

  AppVersionRepository(
    this._api, {
    Duration checkTimeout = AppVersionRepository.versionCheckTimeout,
    bool isUpdateCheckSkipped = isTestBuild,
  }) : _checkTimeout = checkTimeout,
       _isUpdateCheckSkipped = isUpdateCheckSkipped;

  /// 서버 응답 기준 업데이트 타입 (조회 실패·제한 시간 초과 시 null)
  Future<UpdateType?> fetchServerUpdateType() {
    // 테스트 빌드 (API 호출 없이 none)
    if (_isUpdateCheckSkipped) {
      debugPrint('[app version] check skipped : test build');
      return Future.value(UpdateType.none);
    }
    return _api.fetchUpdateType().timeout(
      _checkTimeout,
      onTimeout: () {
        debugPrint('[app version] check timed out : ${_checkTimeout.inSeconds}s > pass');
        return null;
      },
    );
  }

  /// 시작 흐름용 업데이트 타입 (판정 불가 시 none, 차단하지 않음)
  Future<UpdateType> checkUpdateType() async => await fetchServerUpdateType() ?? UpdateType.none;
}
