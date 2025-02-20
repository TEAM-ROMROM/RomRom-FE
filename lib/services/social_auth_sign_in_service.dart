import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:romrom_fe/main.dart';
import 'package:romrom_fe/models/tokens.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/services/response_printer.dart';
import 'package:romrom_fe/services/token_manage.dart';

/// POST : `/api/auth/sign-in` 소셜 로그인
Future<void> signInWithSocial({
  required String socialPlatform,
}) async {
  const String url = '$baseUrl/api/auth/sign-in';

  try {
    // multipart 형식 요청
    var request = http.MultipartRequest('POST', Uri.parse(url));

    var userInfo = UserInfo().getUserInfo();

    // 요청 파라미터 추가 (플랫폼, 유저 정보)
    request.fields['socialPlatform'] = socialPlatform;
    userInfo.forEach((key, value) {
      request.fields[key] = value ?? '';
    });

    // 요청 보내기
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // 응답 데이터 출력
      responsePrinter(url, responseData);

      // 로컬 저장소에 토큰 저장
      String accessToken = responseData[Tokens.accessToken.name];
      String refreshToken = responseData[Tokens.refreshToken.name];

      saveTokens(accessToken, refreshToken);
    } else {
      throw Exception('Failed to sign in: ${response.body}');
    }
  } catch (error) {
    throw Exception('Error during sign-in: $error');
  }
}

/// POST : `/api/auth/logout` 로그아웃
Future<void> logOutWithSocial() async {
  const String url = '$baseUrl/api/auth/logout';

  try {
    // multipart 형식 요청
    var request = http.MultipartRequest('POST', Uri.parse(url));

    // 요청 파라미터 추가 (플랫폼, 유저 정보)

    // 요청 보내기
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // 응답 데이터 출력
      responsePrinter(url, responseData);

      // 로컬 저장소에 토큰 저장
      String accessToken = responseData[Tokens.accessToken.name];
      String refreshToken = responseData[Tokens.refreshToken.name];

      saveTokens(accessToken, refreshToken);
    } else {
      throw Exception('Failed to sign in: ${response.body}');
    }
  } catch (error) {
    throw Exception('Error during sign-in: $error');
  }
}
