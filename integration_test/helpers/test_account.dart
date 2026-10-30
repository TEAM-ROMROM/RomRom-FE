import 'package:romrom_fe/enums/login_platforms.dart';

/// E2E 테스트 계정: 두 계정이 필요한 플로우(요청 보내기 <-> 받기)에서 역할 구분
/// 계정 정보는 test_credentials.dart (.env 의 TEST_KAKAO_*, TEST_GOOGLE_*)
enum TestAccount {
  // 기본 계정 (카카오): 단독 플로우 + 요청 보내는 쪽
  primaryKakao(loginPlatform: LoginPlatforms.kakao),

  // 보조 계정 (구글): 요청 받는 쪽
  secondaryGoogle(loginPlatform: LoginPlatforms.google);

  final LoginPlatforms loginPlatform;

  const TestAccount({required this.loginPlatform});
}
