import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:romrom_fe/enums/token_keys.dart';

class TokenManager {
  static const storage = FlutterSecureStorage();

  /// 토큰 저장
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await storage.write(key: TokenKeys.accessToken.name, value: accessToken);
    await storage.write(key: TokenKeys.refreshToken.name, value: refreshToken);
  }

  /// 액세스 토큰 불러오기
  Future<String?> getAccessToken() async {
    return await storage.read(key: TokenKeys.accessToken.name);
  }

  /// 리프레시 토큰 불러오기
  Future<String?> getRefreshToken() async {
    return await storage.read(key: TokenKeys.refreshToken.name);
  }

  /// 토큰 삭제
  Future<void> deleteTokens() async {
    await storage.delete(key: TokenKeys.accessToken.name);
    await storage.delete(key: TokenKeys.refreshToken.name);
  }
}
