/// 동일 이메일이 다른 소셜 플랫폼으로 이미 가입되어 있을 때 발생하는 예외 (HTTP 409)
class EmailAlreadyRegisteredException implements Exception {
  final String registeredSocialPlatform;

  EmailAlreadyRegisteredException({required this.registeredSocialPlatform});

  /// registeredSocialPlatform 값을 한글 표시명으로 변환
  String get displayPlatformName {
    switch (registeredSocialPlatform) {
      case 'KAKAO':
        return '카카오';
      case 'GOOGLE':
        return '구글';
      case 'APPLE':
        return 'Apple';
      default:
        return registeredSocialPlatform;
    }
  }

  @override
  String toString() => 'EmailAlreadyRegisteredException: registeredSocialPlatform=$registeredSocialPlatform';
}
