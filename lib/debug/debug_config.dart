import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 테스트 빌드 설정 관리
/// .env 파일의 TEST_BUILD=true 여부로 디버그 도구 활성화 결정
class DebugConfig {
  static bool _isTestBuild = false;

  /// 테스트 빌드 여부 (읽기 전용)
  static bool get isTestBuild => _isTestBuild;

  /// 앱 초기화 시 1회 호출 (.env 로드 이후)
  static void init() {
    final value = dotenv.get('TEST_BUILD', fallback: 'false');
    _isTestBuild = value.toLowerCase() == 'true';
  }
}
