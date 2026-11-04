import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/responses/app_version_response.dart';

/// 플랫폼별 최신 버전 검증: 플랫폼 값 우선, 비어 있음(구버전 서버) > 공통 최신 버전
void main() {
  test('플랫폼 값 있음 > 실행 플랫폼 값', () {
    final versionResponse = AppVersionResponse.fromJson({
      'latestVersion': '1.10.142',
      'latestVersionIos': '1.10.142',
      'latestVersionAndroid': '1.10.143',
    });

    expect(versionResponse.latestVersionFor(isIos: true), '1.10.142');
    expect(versionResponse.latestVersionFor(isIos: false), '1.10.143');
  });

  test('구버전 서버(플랫폼 값 없음) > 공통 최신 버전', () {
    final versionResponse = AppVersionResponse.fromJson({'latestVersion': '1.10.142'});

    expect(versionResponse.latestVersionFor(isIos: true), '1.10.142');
    expect(versionResponse.latestVersionFor(isIos: false), '1.10.142');
  });
}
