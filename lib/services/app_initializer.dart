import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:logging/logging.dart';

/// 앱 초기화 함수
Future<void> initialize() async {
  await loadEnv(); // .env 파일 로딩
  await initNaverMap(); // 네이버 지도 초기화
  await initGoogleSignIn(); // Google Sign-In 초기화 (v7 필수)
  initKakaoSdk(); // 카카오 sdk 초기화
  initLogger(); // logger 초기화
}

/// .env 파일 로드
Future<void> loadEnv() async {
  await dotenv.load(fileName: ".env");
}

/// 네이버 맵 SDK 초기화
Future<void> initNaverMap() async {
  final flutterNaverMap = FlutterNaverMap();
  await flutterNaverMap.init(clientId: dotenv.get('NMF_CLIENT_ID'), onAuthFailed: (ex) => Logger("네이버맵 인증오류"));
}

/// Google Sign-In 초기화 (google_sign_in v7 필수)
/// Android: serverClientId (web client ID) 없으면 clientConfigurationError 발생
Future<void> initGoogleSignIn() async {
  await GoogleSignIn.instance.initialize(serverClientId: dotenv.get('GOOGLE_SERVER_CLIENT_ID'));
  debugPrint('[AppInit] Google Sign-In 초기화 완료');
}

/// 카카오 SDK 초기화
void initKakaoSdk() {
  KakaoSdk.init(nativeAppKey: dotenv.get('KAKAO_NATIVE_APP_KEY'));
}

/// Logger 초기화
void initLogger() {
  Logger.root.level = Level.ALL; // 모든 로그 출력
  Logger.root.onRecord.listen((record) {
    debugPrint('[${record.level.name}] ${record.time}: ${record.loggerName} - ${record.message}');
  });
}
