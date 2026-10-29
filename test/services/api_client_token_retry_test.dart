import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/services/api_client.dart';

void main() {
  group('ApiClient.shouldReissueToken', () {
    test('보낸 토큰 == 저장 토큰 > 재발급', () {
      expect(ApiClient.shouldReissueToken(sentAccessToken: 'old', storedAccessToken: 'old'), isTrue);
    });

    test('저장 토큰이 이미 바뀜 (다른 요청이 재발급) > 재발급 없이 재시도', () {
      expect(ApiClient.shouldReissueToken(sentAccessToken: 'old', storedAccessToken: 'new'), isFalse);
    });

    test('저장 토큰 없음 > 재발급 경로 (실패 처리)', () {
      expect(ApiClient.shouldReissueToken(sentAccessToken: 'old', storedAccessToken: null), isTrue);
    });
  });
}
