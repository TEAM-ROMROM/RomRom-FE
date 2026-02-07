import 'package:patrol/patrol.dart';

import 'helpers/app_helper.dart';
import 'helpers/test_credentials.dart';

void main() {
  patrolTest('카카오 자동 로그인 테스트', ($) async {
    await initAndRunTestApp($);

    // 1. 카카오 로그인 버튼 탭
    await $('카카오로 시작하기').tap();
    await $.pumpAndSettle();

    // 2. 네이티브 WebView에서 카카오 로그인 처리
    // Patrol의 platformAutomator 기능 사용
    // ignore: deprecated_member_use
    await $.native.enterTextByIndex(KakaoTestCredentials.email, index: 0);
    // ignore: deprecated_member_use
    await $.native.enterTextByIndex(KakaoTestCredentials.password, index: 1);
    // ignore: deprecated_member_use
    await $.native.tap(Selector(text: '로그인'));

    // 3. 로그인 성공 후 화면 전환 대기
    await $.pump(const Duration(seconds: 5));
    await $.pumpAndSettle();

    // 4. 로그인 성공 확인 (온보딩 또는 홈 화면)
    // 실제 앱 구조에 맞게 조정 필요
  });

  patrolTest('구글 자동 로그인 테스트', ($) async {
    await initAndRunTestApp($);

    // 1. 구글 로그인 버튼 탭
    await $('구글로 시작하기').tap();
    await $.pumpAndSettle();

    // 2. 네이티브 구글 로그인 처리
    // 구글 로그인은 시스템 다이얼로그를 사용하므로 다르게 처리 필요
    await $.pump(const Duration(seconds: 3));

    // 구글 계정 선택 또는 로그인 처리
    // ignore: deprecated_member_use
    await $.native.enterTextByIndex(GoogleTestCredentials.email, index: 0);
    // ignore: deprecated_member_use
    await $.native.tap(Selector(text: '다음'));
    await $.pump(const Duration(seconds: 2));

    // ignore: deprecated_member_use
    await $.native.enterTextByIndex(GoogleTestCredentials.password, index: 0);
    // ignore: deprecated_member_use
    await $.native.tap(Selector(text: '다음'));

    // 3. 로그인 성공 후 화면 전환 대기
    await $.pump(const Duration(seconds: 5));
    await $.pumpAndSettle();
  });
}
