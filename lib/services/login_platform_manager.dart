import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:romrom_fe/enums/storage_keys.dart';

/// 로그인 플랫폼 관리(secureStorage) class
class LoginPlatformManager {
  static const _storage = FlutterSecureStorage();

  /// 로그인 플랫폼 저장
  Future<void> saveLoginPlatform(String platform) async {
    await _storage.write(key: StorageKeys.loginPlatform.key, value: platform);
    debugPrint('로그인 플랫폼 저장 성공 : $platform');
  }

  /// 로그인 플랫폼 가져오기
  Future<String?> getLoginPlatform() async {
    return await _storage.read(key: StorageKeys.loginPlatform.key);
  }

  /// 로그인 플랫폼 삭제
  Future<void> deleteLoginPlatform() async {
    await _storage.delete(key: StorageKeys.loginPlatform.key);
    debugPrint('로그인 플랫폼 삭제 성공');
  }
}
