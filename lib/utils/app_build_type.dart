// 테스트 빌드 여부: 최소 버전 강제 업데이트 확인 생략 (#996)
// ROMROM-IOS-TEST-TESTFLIGHT.yaml, android/fastlane/Fastfile(ROMROM-ANDROID-TEST-APK.yaml이 호출)이 --dart-define=IS_TEST_BUILD=true 전달
const bool isTestBuild = bool.fromEnvironment('IS_TEST_BUILD');
