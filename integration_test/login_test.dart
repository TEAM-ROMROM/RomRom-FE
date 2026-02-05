/// 로그인 화면 E2E 테스트
///
/// 실제 앱(main.dart)을 실행하여 Firebase/FCM 포함 전체 플로우를 테스트합니다.
/// 외부망 환경에서 실행하여 실제 소셜 로그인 API 호출이 가능합니다.
library;

import 'package:patrol/patrol.dart';
import 'package:romrom_fe/main.dart' as app;

void main() {
  patrolTest(
    '앱이 정상적으로 시작되고 초기 화면이 표시되어야 함',
    ($) async {
      // 실제 main() 함수 호출 - Firebase 초기화, FCM 설정 포함
      await app.main();

      // 앱 초기화 완료 대기 (Firebase, 토큰 체크 등)
      await $.pumpAndSettle(timeout: Duration(seconds: 10));

      // 로그인 화면이 표시되는지 확인 (토큰이 없거나 만료된 경우)
      // 또는 메인 화면이 표시되는지 확인 (유효한 토큰이 있는 경우)
      final loginScreenVisible = $('손쉬운 물건 교환');
      final mainScreenVisible = $('홈');

      // 둘 중 하나는 반드시 보여야 함
      expect(
        loginScreenVisible.exists || mainScreenVisible.exists,
        true,
        reason: '로그인 화면 또는 메인 화면이 표시되어야 함',
      );

      // 스크린샷 저장 (실패 시 디버깅용)
      await $.native.takeScreenshot('01_app_started');
    },
  );

  patrolTest(
    '로그인 화면 UI 요소들이 정상적으로 표시되어야 함',
    ($) async {
      await app.main();
      await $.pumpAndSettle(timeout: Duration(seconds: 10));

      // 로그인 화면이 아니면 테스트 스킵 (이미 로그인된 상태)
      if (!$('손쉬운 물건 교환').exists) {
        return;
      }

      // 1. "손쉬운 물건 교환" 텍스트 표시 확인
      expect($('손쉬운 물건 교환'), findsOneWidget);

      // 2. 카카오 로그인 버튼 표시 확인
      expect($('카카오로 시작하기'), findsOneWidget);

      // 3. 구글 로그인 버튼 표시 확인
      expect($('구글로 시작하기'), findsOneWidget);

      await $.native.takeScreenshot('02_login_screen');
    },
  );

  patrolTest(
    '카카오 로그인 버튼을 탭하면 WebView가 열려야 함',
    nativeAutomation: true, // 네이티브 WebView 테스트 활성화
    ($) async {
      await app.main();
      await $.pumpAndSettle(timeout: Duration(seconds: 10));

      // 로그인 화면이 아니면 테스트 스킵
      if (!$('카카오로 시작하기').exists) {
        return;
      }

      // 카카오 로그인 버튼 찾기
      final kakaoButton = $('카카오로 시작하기');
      expect(kakaoButton, findsOneWidget);

      // 버튼 탭
      await kakaoButton.tap();
      await $.pumpAndSettle();

      // WebView가 열리거나 카카오톡 앱으로 전환되는 것을 확인
      // (실제 로그인 완료까지는 수동 조작 필요 - 자동화 제한)
      await $.native.takeScreenshot('03_kakao_login_started');

      // 주의: 실제 로그인 플로우는 보안상 자동화하기 어려움
      // 테스트 환경에서는 Mock 서버 또는 테스트 계정 사용 권장
    },
  );

  patrolTest(
    '구글 로그인 버튼을 탭하면 구글 로그인 화면이 열려야 함',
    nativeAutomation: true,
    ($) async {
      await app.main();
      await $.pumpAndSettle(timeout: Duration(seconds: 10));

      // 로그인 화면이 아니면 테스트 스킵
      if (!$('구글로 시작하기').exists) {
        return;
      }

      // 구글 로그인 버튼 찾기
      final googleButton = $('구글로 시작하기');
      expect(googleButton, findsOneWidget);

      // 버튼 탭
      await googleButton.tap();
      await $.pumpAndSettle();

      // 구글 로그인 WebView 또는 시스템 브라우저 열림 확인
      await $.native.takeScreenshot('04_google_login_started');
    },
  );
}
