import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/marketing_consent_message.dart';

/// 마케팅 수신 동의 변경 안내 문구 (처리 일자 포함)
void main() {
  test('동의 > yyyy.MM.dd 마케팅 정보 수신 동의 처리', () {
    expect(
      buildMarketingConsentMessage(isAgreed: true, processedAt: DateTime(2026, 11, 3, 9)),
      '2026.11.03 마케팅 정보 수신 동의 처리되었어요',
    );
  });

  test('거부 > 거부 처리, 월·일 두 자리', () {
    expect(
      buildMarketingConsentMessage(isAgreed: false, processedAt: DateTime(2027, 1, 5)),
      '2027.01.05 마케팅 정보 수신 거부 처리되었어요',
    );
  });
}
