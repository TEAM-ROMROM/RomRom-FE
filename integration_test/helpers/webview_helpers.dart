/// WebView 자동화 헬퍼 함수
///
/// Patrol의 네이티브 API를 사용하여 WebView 내부 DOM 요소를 제어합니다.
library;

import 'package:patrol/patrol.dart';

/// 카카오 로그인 WebView 자동화
class KakaoWebViewHelper {
  /// 카카오 로그인 자동 완료
  ///
  /// [email]: 카카오 계정 이메일
  /// [password]: 카카오 계정 비밀번호
  /// [waitSeconds]: WebView 로딩 대기 시간 (기본 3초)
  static Future<bool> autoLogin(
    PatrolTester $, {
    required String email,
    required String password,
    int waitSeconds = 3,
  }) async {
    try {
      // WebView 로딩 대기
      await Future.delayed(Duration(seconds: waitSeconds));

      // 방법 1: resourceId로 시도 (가장 안정적)
      bool emailEntered = await _tryEnterEmail($, email, method: 'resourceId');
      if (!emailEntered) {
        // 방법 2: className + index로 재시도
        emailEntered = await _tryEnterEmail($, email, method: 'className');
      }
      if (!emailEntered) {
        throw Exception('이메일 입력 필드를 찾을 수 없습니다');
      }

      await Future.delayed(Duration(milliseconds: 500));

      // 비밀번호 입력
      bool passwordEntered = await _tryEnterPassword($, password, method: 'resourceId');
      if (!passwordEntered) {
        passwordEntered = await _tryEnterPassword($, password, method: 'className');
      }
      if (!passwordEntered) {
        throw Exception('비밀번호 입력 필드를 찾을 수 없습니다');
      }

      await Future.delayed(Duration(milliseconds: 500));

      // 로그인 버튼 탭
      bool loginTapped = await _tryTapLoginButton($);
      if (!loginTapped) {
        throw Exception('로그인 버튼을 찾을 수 없습니다');
      }

      return true;
    } catch (e) {
      print('❌ 카카오 자동 로그인 실패: $e');
      return false;
    }
  }

  /// 이메일 입력 시도
  static Future<bool> _tryEnterEmail(
    PatrolTester $,
    String email, {
    required String method,
  }) async {
    try {
      if (method == 'resourceId') {
        // <input id="loginId--1" name="loginId" />
        final field = $.native.find(Selector(resourceIdMatches: 'loginId.*'));
        if (!field.exists) return false;

        await field.tap();
        await $.native.enterTextByIndex(email, index: 0);
        return true;
      } else if (method == 'className') {
        // <input class="input_txt" />
        await $.native.tap(Selector(className: 'input_txt', index: 0));
        await $.native.enterTextByIndex(email, index: 0);
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  /// 비밀번호 입력 시도
  static Future<bool> _tryEnterPassword(
    PatrolTester $,
    String password, {
    required String method,
  }) async {
    try {
      if (method == 'resourceId') {
        final field = $.native.find(Selector(resourceIdMatches: 'password.*'));
        if (!field.exists) return false;

        await field.tap();
        await $.native.enterTextByIndex(password, index: 1);
        return true;
      } else if (method == 'className') {
        await $.native.tap(Selector(className: 'input_txt', index: 1));
        await $.native.enterTextByIndex(password, index: 1);
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  /// 로그인 버튼 탭 시도
  static Future<bool> _tryTapLoginButton(PatrolTester $) async {
    try {
      // 방법 1: 텍스트로 찾기
      await $.native.tap(Selector(text: '로그인'));
      return true;
    } catch (e) {
      try {
        // 방법 2: className으로 찾기
        await $.native.tap(Selector(className: 'btn_confirm'));
        return true;
      } catch (e) {
        return false;
      }
    }
  }
}

/// 구글 로그인 WebView 자동화
class GoogleWebViewHelper {
  /// 구글 로그인 자동 완료 (2단계)
  static Future<bool> autoLogin(
    PatrolTester $, {
    required String email,
    required String password,
  }) async {
    try {
      await Future.delayed(Duration(seconds: 3));

      // 1단계: 이메일 입력
      await $.native.tap(Selector(resourceId: 'identifierId'));
      await $.native.enterText(Selector(resourceId: 'identifierId'), email);
      await $.native.tap(Selector(text: '다음'));

      await Future.delayed(Duration(seconds: 2));

      // 2단계: 비밀번호 입력
      await $.native.tap(Selector(textContains: 'password'));
      await $.native.enterText(Selector(textContains: 'password'), password);
      await $.native.tap(Selector(text: '다음'));

      return true;
    } catch (e) {
      print('❌ 구글 자동 로그인 실패: $e');
      return false;
    }
  }
}

/// WebView 디버깅 헬퍼
class WebViewDebugHelper {
  /// WebView DOM 구조 출력 (디버깅용)
  static void printDOMGuide() {
    print('');
    print('═══════════════════════════════════════');
    print('  WebView DOM 디버깅 가이드');
    print('═══════════════════════════════════════');
    print('');
    print('📱 Chrome Remote Debugging 연결:');
    print('   1. Chrome 브라우저에서 chrome://inspect 접속');
    print('   2. 에뮬레이터의 WebView 선택');
    print('   3. "inspect" 클릭');
    print('');
    print('🔍 확인할 항목:');
    print('   - Elements 탭에서 input 필드 찾기');
    print('   - 우클릭 → Copy → Copy element');
    print('');
    print('📝 HTML 예시:');
    print('   <input id="loginId--1" class="tf_g" name="loginId">');
    print('   <input id="password--2" class="tf_g" name="password">');
    print('   <button class="btn_confirm">로그인</button>');
    print('');
    print('⚙️ Selector 작성법:');
    print('   - resourceId: Selector(resourceId: "loginId--1")');
    print('   - className: Selector(className: "tf_g", index: 0)');
    print('   - text: Selector(text: "로그인")');
    print('   - 정규식: Selector(resourceIdMatches: "loginId.*")');
    print('');
    print('💡 여러 방법 시도:');
    print('   1. resourceId (가장 안정적)');
    print('   2. className + index');
    print('   3. text');
    print('   4. textContains');
    print('');
    print('═══════════════════════════════════════');
    print('');
  }

  /// 스크린샷 저장 및 가이드 출력
  static Future<void> captureAndGuide(
    PatrolTester $,
    String screenshotName,
  ) async {
    await $.native.takeScreenshot(screenshotName);
    print('📸 스크린샷 저장: $screenshotName.png');
    printDOMGuide();
  }
}
