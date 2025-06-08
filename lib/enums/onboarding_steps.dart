/// 온보딩 단계
enum OnboardingSteps {
  termAgreement(
    step: 1,
    title: '이용약관 동의',
    subtitle: '회원가입전, romrom 약관들을 확인해주세요',
  ),
  locationVerification(
    step: 2,
    title: '동네 인증하기',
    subtitle: '내 위치를 인증해주세요',
  ),
  categorySelection(
    step: 3,
    title: '카테고리 선택',
    subtitle: '관심있는 분야를 선택해주세요!',
  );

  final int step;
  final String title;
  final String subtitle;

  const OnboardingSteps({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  /// 단계 번호로 OnboardingSteps 가져오기
  static OnboardingSteps fromStep(int step) {
    return values.firstWhere(
      (element) => element.step == step,
      orElse: () => termAgreement,
    );
  }
}