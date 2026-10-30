import 'package:patrol/patrol.dart';
import 'package:romrom_fe/widgets/custom_bottom_navigation_bar.dart';

import 'app_helper.dart';
import 'common_ui_helper.dart';
import 'test_account.dart';
import 'test_credentials.dart';

// 로그인 후 메인 화면 진입 최대 대기 (소셜 인증 + 서버 로그인 + 회원 정보 조회)
const Duration mainScreenEntryTimeout = Duration(seconds: 90);

// 소셜 로그인 화면(WebView·시스템 화면) 전환 대기
const Duration socialLoginScreenTransitionWait = Duration(seconds: 3);

/// 앱 실행 > 테스트 계정 소셜 로그인 > 메인 화면 진입 > 시작 팝업 정리 (모든 플로우 공통 시작점)
Future<void> launchAppLoggedInAs(PatrolIntegrationTester $, TestAccount account) async {
  await initAndRunTestApp($);

  await $(account.loginPlatform.displayText).tap();
  await $.pumpAndTrySettle();

  switch (account) {
    case TestAccount.primaryKakao:
      await _enterKakaoCredentials($);
    case TestAccount.secondaryGoogle:
      await _enterGoogleCredentials($);
  }

  // 로그인 성공 > 하단 탭이 있는 메인 화면 (온보딩이 필요한 신규 계정이면 여기서 타임아웃)
  await $(CustomBottomNavigationBar).waitUntilVisible(timeout: mainScreenEntryTimeout);
  await dismissStartupOverlays($);
}

/// 카카오 계정 로그인 WebView: 이메일 > 비밀번호 > 로그인 버튼
Future<void> _enterKakaoCredentials(PatrolIntegrationTester $) async {
  await $.platform.mobile.enterTextByIndex(KakaoTestCredentials.email, index: 0);
  await $.platform.mobile.enterTextByIndex(KakaoTestCredentials.password, index: 1);
  await $.platform.mobile.tap(Selector(text: KakaoTestCredentials.loginButtonSelector));
}

/// 구글 계정 로그인 시스템 화면: 이메일 > 다음 > 비밀번호 > 다음
Future<void> _enterGoogleCredentials(PatrolIntegrationTester $) async {
  await $.pump(socialLoginScreenTransitionWait);

  await $.platform.mobile.enterTextByIndex(GoogleTestCredentials.email, index: 0);
  await $.platform.mobile.tap(Selector(text: '다음'));
  await $.pump(socialLoginScreenTransitionWait);

  await $.platform.mobile.enterTextByIndex(GoogleTestCredentials.password, index: 0);
  await $.platform.mobile.tap(Selector(text: '다음'));
}
