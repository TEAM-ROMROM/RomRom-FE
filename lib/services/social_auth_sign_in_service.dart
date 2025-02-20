import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:romrom_fe/main.dart';
import 'package:romrom_fe/models/platforms.dart';
import 'package:romrom_fe/models/tokens.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/services/google_auth_manager.dart';
import 'package:romrom_fe/services/kakao_auth_manager.dart';
import 'package:romrom_fe/services/response_printer.dart';
import 'package:romrom_fe/services/send_authenticated_request.dart';
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
Future<void> logOutWithSocial(BuildContext context) async {
  const String url = '$baseUrl/api/auth/logout';
  try {
    await sendAuthenticatedRequest(
      url: url,
      body: {
        Tokens.accessToken.name: await getAccessToken(),
        Tokens.refreshToken.name: await getRefreshToken(),
      },
      onSuccess: (responseData) async {
        responsePrinter(url, responseData);
        // 토큰 삭제
        await deleteTokens();
        // 소셜 로그아웃
        Platforms platform = UserInfo().getLoginPlatform();
        final KakaoAuthService kakaoAuthService = KakaoAuthService();
        final GoogleAuthService googleAuthService = GoogleAuthService();

        switch (platform) {
          case Platforms.KAKAO:
            // 카카오 로그아웃 처리
            kakaoAuthService.logoutWithKakaoAccount();
            break;
          case Platforms.GOOGLE:
            // 구글 로그아웃 로직 처리
            googleAuthService.logOutWithGoogle();
        }

        // 로그인화면으로 이동
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => const LoginScreen(),
          ),
        );
      },
    );
  } catch (error) {
    debugPrint("로그아웃 실패: $error");
    throw Exception('Error during log-out: $error');
  }
}
