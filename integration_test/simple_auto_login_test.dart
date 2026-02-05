/// 간결한 자동 로그인 테스트
///
/// WebView 헬퍼 함수를 사용하여 코드 간소화
library;

import 'package:patrol/patrol.dart';
import 'package:romrom_fe/main.dart' as app;

import 'helpers/webview_helpers.dart';

void main() {
  patrolTest(
    '카카오 자동 로그인 (헬퍼 사용)',
    nativeAutomation: true,
    ($) async {
      // 앱 시작
      await app.main();
      await $.pumpAndSettle(timeout: Duration(seconds: 10));

      if (!$('카카오로 시작하기').exists) {
        print('⚠️ 이미 로그인됨');
        return;
      }

      // 카카오 로그인 버튼 탭
      await $('카카오로 시작하기').tap();
      await $.pumpAndSettle();

      // WebView 자동 로그인 (헬퍼 함수 사용)
      final success = await KakaoWebViewHelper.autoLogin(
        $,
        email: 'test-kakao@example.com', // 실제 계정으로 변경
        password: 'testPassword123!', // 실제 비밀번호로 변경
      );

      if (!success) {
        // 디버깅 가이드 출력
        await WebViewDebugHelper.captureAndGuide($, 'kakao_login_failed');
        fail('카카오 자동 로그인 실패');
      }

      // 로그인 완료 대기
      await Future.delayed(Duration(seconds: 5));
      await $.pumpAndSettle(timeout: Duration(seconds: 10));

      // 온보딩 화면 처리
      if ($('시작하기').exists || $('다음').exists) {
        while ($('다음').exists) {
          await $('다음').tap();
          await $.pumpAndSettle();
        }
        if ($('시작하기').exists) {
          await $('시작하기').tap();
          await $.pumpAndSettle();
        }
      }

      // 메인 화면 확인
      expect($('홈').exists, true, reason: '로그인 후 메인 화면 진입 실패');

      print('🎉 카카오 자동 로그인 성공!');
    },
  );

  patrolTest(
    '구글 자동 로그인 (헬퍼 사용)',
    nativeAutomation: true,
    ($) async {
      await app.main();
      await $.pumpAndSettle(timeout: Duration(seconds: 10));

      if (!$('구글로 시작하기').exists) {
        print('⚠️ 이미 로그인됨');
        return;
      }

      // 구글 로그인 버튼 탭
      await $('구글로 시작하기').tap();
      await $.pumpAndSettle();

      // WebView 자동 로그인
      final success = await GoogleWebViewHelper.autoLogin(
        $,
        email: 'test-google@gmail.com', // 실제 계정으로 변경
        password: 'testPassword123!', // 실제 비밀번호로 변경
      );

      if (!success) {
        await WebViewDebugHelper.captureAndGuide($, 'google_login_failed');
        fail('구글 자동 로그인 실패');
      }

      await Future.delayed(Duration(seconds: 5));
      await $.pumpAndSettle(timeout: Duration(seconds: 10));

      expect($('홈').exists, true);

      print('🎉 구글 자동 로그인 성공!');
    },
  );
}
