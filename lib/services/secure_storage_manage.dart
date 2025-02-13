import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:romrom_fe/main.dart';
import 'package:http/http.dart' as http;

const storage = FlutterSecureStorage();

/// storage에 값 저장
Future<void> saveSecureData(Map<String, dynamic> obj) async {
  for (var entry in obj.entries) {
    await storage.write(key: entry.key, value: entry.value.toString());
  }
}

/// storage에 저장된 값 가져오기
Future<String?> getSecureData(String name) async {
  return await storage.read(key: name);
}

/// storage에 저장된 값 지우기
Future<void> deleteSecureData(Map<String, dynamic> obj) async {
  for (var entry in obj.entries) {
    await storage.delete(key: entry.key);
  }
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
