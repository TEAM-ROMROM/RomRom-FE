import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:romrom_fe/debug/debug_config.dart';
import 'package:romrom_fe/debug/log_capture.dart';

/// 앱 초기화 함수
Future<void> initialize() async {
  await loadEnv(); // .env 파일 로딩
  DebugConfig.init(); // 테스트 빌드 설정 초기화
  // 테스트 빌드인 경우 debugPrint 캡처 시작
  if (DebugConfig.isTestBuild) {
    LogCapture().start();
  }
  await initNaverMap(); // 네이버 지도 초기화
  await initGoogleSignIn(); // Google Sign-In 초기화 (v7 필수)
  initKakaoSdk(); // 카카오 sdk 초기화
  // UMP 동의 수집 후 MobileAds 초기화 (non-blocking)
  _initConsentAndAds();
}

/// .env 파일 로드
Future<void> loadEnv() async {
  await dotenv.load(fileName: ".env");
}

/// 네이버 맵 SDK 초기화
Future<void> initNaverMap() async {
  final flutterNaverMap = FlutterNaverMap();
  await flutterNaverMap.init(
    clientId: dotenv.get('NMF_CLIENT_ID'),
    onAuthFailed: (ex) => debugPrint('[ERROR] 네이버맵 인증 실패: $ex'),
  );
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

/// UMP 동의 수집 후 Google Mobile Ads 초기화
/// GDPR/CCPA 등 규제 지역에서 개인화 광고 제공 전 사용자 동의 수집 (AdMob 프로그램 정책 필수)
void _initConsentAndAds() {
  ConsentInformation.instance.requestConsentInfoUpdate(
    ConsentRequestParameters(),
    () async {
      debugPrint('[UMP] 동의 정보 업데이트 성공');
      if (await ConsentInformation.instance.isConsentFormAvailable()) {
        ConsentForm.loadConsentForm(
          (ConsentForm form) async {
            final status = await ConsentInformation.instance.getConsentStatus();
            if (status == ConsentStatus.required) {
              form.show((_) async {
                if (await ConsentInformation.instance.canRequestAds()) _initMobileAds();
              });
            } else {
              if (await ConsentInformation.instance.canRequestAds()) _initMobileAds();
            }
          },
          (FormError error) async {
            debugPrint('[UMP] 동의 폼 로드 실패: ${error.message}');
            if (await ConsentInformation.instance.canRequestAds()) _initMobileAds();
          },
        );
      } else {
        if (await ConsentInformation.instance.canRequestAds()) _initMobileAds();
      }
    },
    (FormError error) async {
      debugPrint('[UMP] 동의 정보 업데이트 실패: ${error.message}');
      if (await ConsentInformation.instance.canRequestAds()) _initMobileAds();
    },
  );
}

/// Google Mobile Ads 초기화
void _initMobileAds() {
  MobileAds.instance
      .initialize()
      .then((_) {
        debugPrint('[AppInit] Google Mobile Ads 초기화 완료');
      })
      .catchError((Object e) {
        debugPrint('[ERROR] Google Mobile Ads 초기화 실패: $e');
      });
}
