import 'package:package_info_plus/package_info_plus.dart';

/// 설치 버전 조회 함수 형태 (테스트 교체용)
typedef InstalledAppVersionReader = Future<String> Function();

/// 플랫폼 설치 버전 조회 (PackageInfo, 첫 성공 결과는 플러그인이 캐시)
Future<String> readPlatformAppVersion() async => (await PackageInfo.fromPlatform()).version;

/// 설치된 앱 버전 조회 (예: "1.9.67")
/// 플랫폼 조회 실패 시 [fallbackVersion] 반환 — 버전은 표시·진단용이라 실패해도 화면·요청 흐름은 계속 진행
Future<String> fetchInstalledAppVersion({
  String fallbackVersion = '',
  InstalledAppVersionReader readInstalledAppVersion = readPlatformAppVersion,
}) async {
  try {
    return await readInstalledAppVersion();
  } catch (_) {
    return fallbackVersion;
  }
}
