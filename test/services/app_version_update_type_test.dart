import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/app_update_type.dart';
import 'package:romrom_fe/services/apis/app_version_api.dart';

/// 현재 버전 <-> 서버 최소·최신 버전 > 강제·권장·불필요
void main() {
  final appVersionApi = AppVersionApi();

  test('최소 버전 미달 > 강제', () {
    expect(
      appVersionApi.resolveUpdateType(currentVersion: '1.9.0', minimumVersion: '1.10.0', latestVersion: '1.10.129'),
      UpdateType.force,
    );
  });

  test('최소 이상, 최신 미달 > 권장', () {
    expect(
      appVersionApi.resolveUpdateType(currentVersion: '1.10.100', minimumVersion: '1.10.0', latestVersion: '1.10.129'),
      UpdateType.recommend,
    );
  });

  test('최신 이상 > 불필요', () {
    expect(
      appVersionApi.resolveUpdateType(currentVersion: '1.10.129', minimumVersion: '1.10.0', latestVersion: '1.10.129'),
      UpdateType.none,
    );
  });

  test('최신 버전 형식 오류 > 강제 판정은 유지, 권장은 생략', () {
    expect(
      appVersionApi.resolveUpdateType(currentVersion: '1.10.1', minimumVersion: '1.10.0', latestVersion: 'latest'),
      UpdateType.none,
    );
    expect(
      appVersionApi.resolveUpdateType(currentVersion: '1.9.0', minimumVersion: '1.10.0', latestVersion: 'latest'),
      UpdateType.force,
    );
  });
}
