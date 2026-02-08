import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 카카오 테스트 계정 정보 (.env에서 로드)
class KakaoTestCredentials {
  static String get email => dotenv.get('TEST_KAKAO_EMAIL');
  static String get password => dotenv.get('TEST_KAKAO_PASSWORD');

  // 카카오 WebView DOM 셀렉터 (변경 시 수정)
  static const String emailFieldSelector = 'loginId--1';
  static const String passwordFieldSelector = 'password--2';
  static const String loginButtonSelector = '로그인';
}

/// 구글 테스트 계정 정보 (.env에서 로드)
class GoogleTestCredentials {
  static String get email => dotenv.get('TEST_GOOGLE_EMAIL');
  static String get password => dotenv.get('TEST_GOOGLE_PASSWORD');

  // 구글 로그인 WebView DOM 셀렉터
  static const String emailFieldSelector = 'identifierId';
  static const String emailNextButtonSelector = 'identifierNext';
  static const String passwordFieldSelector = 'password';
  static const String passwordNextButtonSelector = 'passwordNext';
}
