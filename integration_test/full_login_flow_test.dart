/// 전체 로그인 플로우 E2E 테스트
///
/// 실제 소셜 로그인 완료 후 메인 화면까지 진입하는 전체 플로우를 테스트합니다.
/// 외부망 환경 + 테스트 계정 필요
///
/// 실행 방법:
/// 1. Android 에뮬레이터 실행
/// 2. patrol test integration_test/full_login_flow_test.dart
/// 3. WebView에서 수동으로 로그인 진행 (또는 자동화 설정)
library;

import 'package:patrol/patrol.dart';
import 'package:romrom_fe/main.dart' as app;

void main() {
  patrolTest(
    '[수동] 카카오 로그인 전체 플로우 - 로그인부터 메인 화면까지',
    nativeAutomation: true,
    ($) async {
      // 실제 앱 시작
      await app.main();
      await $.pumpAndSettle(timeout: Duration(seconds: 10));

      // 로그인 화면 확인
      if (!$('카카오로 시작하기').exists) {
        print('이미 로그인된 상태입니다. 로그아웃 후 테스트하세요.');
        return;
      }

      // 1. 카카오 로그인 버튼 탭
      await $('카카오로 시작하기').tap();
      await $.pumpAndSettle();

      print('====================================');
      print('수동 작업 필요:');
      print('1. WebView에서 카카오 로그인 진행');
      print('2. 테스트 계정으로 로그인 완료');
      print('3. 로그인 완료 후 자동으로 진행됩니다.');
      print('====================================');

      // 2. 로그인 처리 대기 (최대 60초)
      // 사용자가 수동으로 WebView에서 로그인 완료할 시간
      await Future.delayed(Duration(seconds: 60));

      // 3. 온보딩 화면 또는 메인 화면 확인
      // 온보딩이 필요한 경우
      if ($('시작하기').exists || $('다음').exists) {
        print('온보딩 화면이 표시되었습니다.');
        await $.native.takeScreenshot('05_onboarding_screen');

        // 온보딩 스킵 (실제 플로우에 맞게 수정)
        while ($('다음').exists) {
          await $('다음').tap();
          await $.pumpAndSettle();
        }

        if ($('시작하기').exists) {
          await $('시작하기').tap();
          await $.pumpAndSettle();
        }
      }

      // 4. 메인 화면 진입 확인
      expect(
        $('홈').exists,
        true,
        reason: '로그인 후 메인 화면의 "홈" 탭이 표시되어야 함',
      );

      await $.native.takeScreenshot('06_main_screen_logged_in');

      print('✅ 로그인 플로우 테스트 완료!');
    },
  );

  patrolTest(
    '[자동화] 네이티브 API를 사용한 카카오 WebView 자동 로그인',
    nativeAutomation: true,
    ($) async {
      await app.main();
      await $.pumpAndSettle(timeout: Duration(seconds: 10));

      if (!$('카카오로 시작하기').exists) {
        return;
      }

      // 카카오 로그인 버튼 탭
      await $('카카오로 시작하기').tap();
      await $.pumpAndSettle();

      // WebView 내부 요소 제어 (네이티브 API 사용)
      // 주의: 실제 카카오 WebView DOM 구조에 따라 셀렉터 수정 필요
      try {
        // 이메일 입력 필드 찾기 (예시 - 실제 DOM 구조 확인 필요)
        await $.native.tap(
          Selector(
            // CSS 셀렉터 또는 accessibility ID 사용
            resourceId: 'loginId--1', // Android
            // label: '이메일 또는 전화번호', // iOS
          ),
        );

        // 테스트 계정 이메일 입력
        await $.native.enterText(
          Selector(resourceId: 'loginId--1'),
          'test@example.com', // 실제 테스트 계정으로 변경
        );

        // 비밀번호 입력 필드
        await $.native.tap(Selector(resourceId: 'password--2'));
        await $.native.enterText(
          Selector(resourceId: 'password--2'),
          'testpassword123', // 실제 테스트 계정 비밀번호로 변경
        );

        // 로그인 버튼 탭
        await $.native.tap(
          Selector(
            text: '로그인',
            // 또는 resourceId: 'btn-login'
          ),
        );

        await $.pumpAndSettle(timeout: Duration(seconds: 10));

        // 메인 화면 진입 확인
        expect($('홈').exists, true);

        print('✅ 자동 로그인 성공!');
      } catch (e) {
        print('❌ 자동 로그인 실패: $e');
        print('WebView DOM 구조를 확인하고 셀렉터를 수정하세요.');

        // 디버깅용 스크린샷
        await $.native.takeScreenshot('error_webview');
        rethrow;
      }
    },
  );

  patrolTest(
    '로그인 후 주요 화면 탐색 테스트',
    ($) async {
      await app.main();
      await $.pumpAndSettle(timeout: Duration(seconds: 10));

      // 로그인 상태 확인
      if (!$('홈').exists) {
        print('로그인되지 않음. 먼저 로그인 테스트를 실행하세요.');
        return;
      }

      // 1. 홈 탭 확인
      expect($('홈'), findsOneWidget);
      await $('홈').tap();
      await $.pumpAndSettle();
      await $.native.takeScreenshot('07_home_tab');

      // 2. 등록 탭 이동
      if ($('등록').exists) {
        await $('등록').tap();
        await $.pumpAndSettle();
        await $.native.takeScreenshot('08_register_tab');
      }

      // 3. 채팅 탭 이동
      if ($('채팅').exists) {
        await $('채팅').tap();
        await $.pumpAndSettle();
        await $.native.takeScreenshot('09_chat_tab');
      }

      // 4. 마이페이지 탭 이동
      if ($('MY').exists || $('마이페이지').exists) {
        await ($('MY').exists ? $('MY') : $('마이페이지')).tap();
        await $.pumpAndSettle();
        await $.native.takeScreenshot('10_mypage_tab');
      }

      print('✅ 탭 네비게이션 테스트 완료!');
    },
  );
}
