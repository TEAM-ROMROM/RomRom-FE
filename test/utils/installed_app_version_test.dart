import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:romrom_fe/utils/installed_app_version.dart';

/// 조회 실패 대역 (플랫폼 채널 미등록 상황 재현)
Future<String> readFailingAppVersion() async => throw Exception('platform unavailable');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 테스트마다 조회 함수를 직접 주입 > 플러그인 캐시·실행 순서와 무관
  group('fetchInstalledAppVersion', () {
    test('조회 실패 시 기본 폴백은 빈 문자열', () async {
      expect(await fetchInstalledAppVersion(readInstalledAppVersion: readFailingAppVersion), '');
    });

    test('조회 실패 시 지정 폴백 반환', () async {
      expect(
        await fetchInstalledAppVersion(fallbackVersion: 'unknown', readInstalledAppVersion: readFailingAppVersion),
        'unknown',
      );
    });

    test('조회 성공 시 설치 버전 반환', () async {
      expect(
        await fetchInstalledAppVersion(fallbackVersion: 'unknown', readInstalledAppVersion: () async => '2.0.1'),
        '2.0.1',
      );
    });

    test('기본 조회 함수는 PackageInfo 버전 사용', () async {
      PackageInfo.setMockInitialValues(
        appName: 'romrom',
        packageName: 'com.romrom.test',
        version: '1.9.67',
        buildNumber: '1',
        buildSignature: '',
      );

      expect(await fetchInstalledAppVersion(fallbackVersion: 'unknown'), '1.9.67');
    });
  });
}
