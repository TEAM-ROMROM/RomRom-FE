import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:romrom_fe/main.dart';
import 'package:http/http.dart' as http;
import 'package:romrom_fe/models/storage_keys.dart';

const storage = FlutterSecureStorage();

/// 토큰 저장
Future<void> saveTokens(String accessToken, String refreshToken) async {
  await storage.write(key: StorageKeys.accessToken.name, value: accessToken);
  await storage.write(key: StorageKeys.refreshToken.name, value: refreshToken);
}

/// 액세스 토큰 불러오기
Future<String?> getAccessToken() async {
  return await storage.read(key: StorageKeys.accessToken.name);
}

/// 리프레시 토큰 불러오기
Future<String?> getRefreshToken() async {
  return await storage.read(key: StorageKeys.refreshToken.name);
}

/// 토큰 삭제
Future<void> deleteTokens() async {
  await storage.delete(key: StorageKeys.accessToken.name);
  await storage.delete(key: StorageKeys.refreshToken.name);
}

/// 엑세스 토큰 재발급
Future<bool> refreshAccessToken() async {
  // 토큰 재발급 api 요청 주소
  // String url = '$baseUrl/api';
  // try {
  //   String? refreshToken = await getRefreshToken();
  //   if (refreshToken == null) {
  //     print('No refresh token found for user.');
  //     return false;
  //   }

  //   // multipart 형식 요청
  //   var request = http.MultipartRequest('POST', Uri.parse(url));

  //   // 요청 파라미터 추가

  //   // 요청 보내기
  //   var streamedResponse = await request.send();
  //   var response = await http.Response.fromStream(streamedResponse);

  //   if (response.statusCode == 200) {
  //     // 토큰 저장
  //     const newAccessToken = '';
  //     const newRefreshToken = '';

  //     await saveTokens(newAccessToken, newRefreshToken);

  //     print('Token refreshed successfully.');
  //     return true;
  //   }

  //   // refresh 만료 -> 강제 로그아웃시키기
  //   else if (response.statusCode == 401) {
  //     print('refresh 만료');
  //     deleteTokens();

  //     return false;
  //   }
  // } catch (e) {
  //   print('Token refresh failed: $e');
  // }
  return false;
}
