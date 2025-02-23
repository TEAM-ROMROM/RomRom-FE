import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:romrom_fe/enums/login_platform_keys.dart';

/// 로그인 플랫폼 관리(secureStorage) class
class LoginPlatformManager {
  static const _storage = FlutterSecureStorage();

  /// 로그인 플랫폼 저장
  Future<void> saveLoginPlatform(String platform) async {
    await _storage.write(
        key: LoginPlatformKeys.loginPlatforms.name, value: platform);
  }

  /// 로그인 플랫폼 가져오기
  Future<String?> getLoginPlatform() async {
    return await _storage.read(key: LoginPlatformKeys.loginPlatforms.name);
  }

  /// 로그인 플랫폼 삭제
  Future<void> deleteLoginPlatform() async {
    await _storage.delete(key: LoginPlatformKeys.loginPlatforms.name);
  }
}
