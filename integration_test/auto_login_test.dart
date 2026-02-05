/// 완전 자동화 로그인 테스트
///
/// WebView 내부 DOM 요소를 직접 제어하여 로그인 자동 완료
/// Patrol의 $.native API 활용
///
/// 사전 준비:
/// 1. helpers/test_credentials_local.dart에 실제 테스트 계정 정보 입력
/// 2. 카카오/구글 WebView DOM 셀렉터 확인 및 수정
library;

import 'package:patrol/patrol.dart';
import 'package:romrom_fe/main.dart' as app;

// 테스트 계정 정보 import (Git에 커밋 안 됨)
// import 'helpers/test_credentials_local.dart';

void main() {
  patrolTest(
    '카카오 로그인 완전 자동화 - WebView 내부 DOM 제어',
    nativeAutomation: true, // 필수!
    ($) async {
      // 실제 앱 시작
      await app.main();
      await $.pumpAndSettle(timeout: Duration(seconds: 10));

      // 로그인 화면 확인
      if (!$('카카오로 시작하기').exists) {
        print('⚠️ 이미 로그인된 상태. 로그아웃 후 재실행하세요.');
        return;
      }

      // 1. 카카오 로그인 버튼 탭
      print('🔵 카카오 로그인 버튼 탭...');
      await $('카카오로 시작하기').tap();
      await $.pumpAndSettle();

      // 2. WebView 로딩 대기 (3초)
      await Future.delayed(Duration(seconds: 3));

      print('🔵 WebView 내부 요소 찾는 중...');

      // 3. WebView 내부 이메일 입력 필드 찾기 및 입력
      // 방법 A: resourceId로 찾기 (Android)
      try {
        // 카카오 로그인 페이지 DOM 구조:
        // <input id="loginId--1" name="loginId" type="text" />
        final emailField = $.native.find(
          Selector(
            resourceIdMatches: 'loginId.*', // 정규식 매칭
          ),
        );

        if (emailField.exists) {
          print('✅ 이메일 필드 발견: resourceId로 찾기');
          await emailField.tap();
          await $.native.enterTextByIndex('test-kakao@example.com', index: 0);
        } else {
          // 방법 B: className + index로 찾기
          print('⚠️ resourceId 미발견. className으로 재시도...');
          await $.native.tap(
            Selector(className: 'input_txt', index: 0),
          );
          await $.native.enterTextByIndex('test-kakao@example.com', index: 0);
        }

        await Future.delayed(Duration(milliseconds: 500));

        // 4. 비밀번호 입력 필드 찾기 및 입력
        // <input id="password--2" name="password" type="password" />
        final passwordField = $.native.find(
          Selector(
            resourceIdMatches: 'password.*',
          ),
        );

        if (passwordField.exists) {
          print('✅ 비밀번호 필드 발견');
          await passwordField.tap();
          await $.native.enterTextByIndex('testPassword123!', index: 1);
        } else {
          print('⚠️ resourceId 미발견. className으로 재시도...');
          await $.native.tap(
            Selector(className: 'input_txt', index: 1),
          );
          await $.native.enterTextByIndex('testPassword123!', index: 1);
        }

        await Future.delayed(Duration(milliseconds: 500));

        // 5. 로그인 버튼 탭
        // <button type="submit">로그인</button>
        print('🔵 로그인 버튼 탭...');
        await $.native.tap(
          Selector(
            // 버튼 텍스트로 찾기
            text: '로그인',
          ),
        );

        // 또는
        // await $.native.tap(
        //   Selector(
        //     className: 'btn_confirm',
        //   ),
        // );

        // 6. 로그인 처리 대기
        print('🔵 로그인 처리 중...');
        await Future.delayed(Duration(seconds: 5));
        await $.pumpAndSettle(timeout: Duration(seconds: 10));

        // 7. 메인 화면 또는 온보딩 화면 확인
        if ($('시작하기').exists || $('다음').exists) {
          print('✅ 온보딩 화면 진입 - 로그인 성공!');
          await $.native.takeScreenshot('login_success_onboarding');

          // 온보딩 스킵
          while ($('다음').exists) {
            await $('다음').tap();
            await $.pumpAndSettle();
          }

          if ($('시작하기').exists) {
            await $('시작하기').tap();
            await $.pumpAndSettle();
          }
        }

        if ($('홈').exists) {
          print('✅ 메인 화면 진입 - 로그인 성공!');
          await $.native.takeScreenshot('login_success_main');
        }

        // 최종 확인
        expect(
          $('홈').exists,
          true,
          reason: '로그인 후 메인 화면의 "홈" 탭이 표시되어야 함',
        );

        print('🎉 완전 자동화 로그인 성공!');
      } catch (e, stackTrace) {
        print('❌ WebView 자동화 실패: $e');
        print('스택 트레이스: $stackTrace');

        // 디버깅용: WebView 스크린샷
        await $.native.takeScreenshot('webview_error');

        // DOM 구조 디버깅 정보 출력
        print('');
        print('🔍 디버깅 가이드:');
        print('1. Chrome Remote Debugging 연결:');
        print('   - chrome://inspect 접속');
        print('   - 에뮬레이터 WebView 선택');
        print('   - Elements 탭에서 input 필드의 id, class 확인');
        print('');
        print('2. 확인할 속성:');
        print('   - <input id="loginId--1"> → resourceId: "loginId--1"');
        print('   - <input class="input_txt"> → className: "input_txt"');
        print('   - <button>로그인</button> → text: "로그인"');
        print('');
        print('3. 셀렉터 수정:');
        print('   - Selector(resourceId: "실제_id")');
        print('   - Selector(className: "실제_class", index: 0)');
        print('   - Selector(text: "실제_버튼_텍스트")');

        rethrow;
      }
    },
  );

  patrolTest(
    '구글 로그인 완전 자동화',
    nativeAutomation: true,
    ($) async {
      await app.main();
      await $.pumpAndSettle(timeout: Duration(seconds: 10));

      if (!$('구글로 시작하기').exists) {
        print('⚠️ 이미 로그인된 상태');
        return;
      }

      // 1. 구글 로그인 버튼 탭
      print('🔴 구글 로그인 버튼 탭...');
      await $('구글로 시작하기').tap();
      await $.pumpAndSettle();
      await Future.delayed(Duration(seconds: 3));

      try {
        // 2. 구글 로그인 첫 번째 단계: 이메일 입력
        print('🔴 이메일 입력...');

        // 구글 로그인 DOM 구조 (2단계):
        // 1단계: <input id="identifierId" type="email" />
        await $.native.tap(Selector(resourceId: 'identifierId'));
        await $.native.enterText(
          Selector(resourceId: 'identifierId'),
          'test-google@gmail.com', // 실제 테스트 계정으로 변경
        );

        // "다음" 버튼 탭
        await $.native.tap(
          Selector(
            // resourceId: 'identifierNext',
            text: '다음',
          ),
        );

        await Future.delayed(Duration(seconds: 2));

        // 3. 두 번째 단계: 비밀번호 입력
        print('🔴 비밀번호 입력...');

        // 2단계: <input name="password" type="password" />
        await $.native.tap(
          Selector(
            // resourceId: 'password', // 또는
            textContains: 'password',
            className: 'whsOnd',
          ),
        );
        await $.native.enterText(
          Selector(textContains: 'password'),
          'testPassword123!',
        );

        // "다음" 버튼 탭
        await $.native.tap(Selector(text: '다음'));

        await Future.delayed(Duration(seconds: 5));
        await $.pumpAndSettle(timeout: Duration(seconds: 10));

        // 4. 로그인 확인
        expect($('홈').exists, true);

        print('🎉 구글 자동 로그인 성공!');
      } catch (e) {
        print('❌ 구글 WebView 자동화 실패: $e');
        await $.native.takeScreenshot('google_webview_error');
        rethrow;
      }
    },
  );

  patrolTest(
    '[디버깅용] WebView DOM 구조 탐색',
    nativeAutomation: true,
    ($) async {
      await app.main();
      await $.pumpAndSettle(timeout: Duration(seconds: 10));

      if (!$('카카오로 시작하기').exists) {
        return;
      }

      await $('카카오로 시작하기').tap();
      await $.pumpAndSettle();
      await Future.delayed(Duration(seconds: 3));

      print('');
      print('═══════════════════════════════════════');
      print('WebView DOM 구조 디버깅');
      print('═══════════════════════════════════════');
      print('');
      print('1. Chrome Remote Debugging 연결:');
      print('   chrome://inspect');
      print('');
      print('2. 현재 WebView에서 확인할 항목:');
      print('   - 이메일 입력 필드의 id, class, name');
      print('   - 비밀번호 입력 필드의 id, class, name');
      print('   - 로그인 버튼의 id, class, text');
      print('');
      print('3. Elements 탭에서 HTML 복사:');
      print('   우클릭 → Copy → Copy element');
      print('');
      print('4. 예시:');
      print('   <input id="loginId--1" class="tf_g" name="loginId">');
      print('   → resourceId: "loginId--1"');
      print('   → className: "tf_g"');
      print('');
      print('5. 셀렉터 작성:');
      print('   Selector(resourceId: "loginId--1")');
      print('   Selector(className: "tf_g", index: 0)');
      print('   Selector(text: "로그인")');
      print('');
      print('6. 스크린샷 저장됨:');

      await $.native.takeScreenshot('webview_dom_debug');

      print('   → webview_dom_debug.png');
      print('');
      print('═══════════════════════════════════════');

      // 30초 대기 (개발자가 DOM 확인할 시간)
      await Future.delayed(Duration(seconds: 30));
    },
  );
}
