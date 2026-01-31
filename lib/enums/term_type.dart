// lib/enums/terms_type.dart
// RomRom 약관 타입 (onboarding : Step1)
enum TermsType {
  service(title: '서비스 이용약관', isRequired: true, contentKey: 'service'),
  privacy(title: '개인정보 수집 및 이용동의', isRequired: true, contentKey: 'privacy'),
  location(title: '위치정보서비스 이용약관', isRequired: true, contentKey: 'location'),
  marketing(title: '마케팅 정보수신 동의', isRequired: false, contentKey: 'marketing', description: '(이메일, SMS, 푸시알림 등)');

  final String title;
  final bool isRequired;
  final String contentKey;
  final String? description;

  const TermsType({required this.title, required this.isRequired, required this.contentKey, this.description});
}
