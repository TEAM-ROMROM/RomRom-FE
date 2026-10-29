import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/app_urls.dart';

void main() {
  group('AppUrls.toAbsoluteImageUrl', () {
    test('상대 경로 > 이미지 서버 절대 주소', () {
      expect(AppUrls.toAbsoluteImageUrl('a/b.jpg'), 'https://suh-project.synology.me/a/b.jpg');
    });

    test('앞 슬래시 중복 제거', () {
      expect(AppUrls.toAbsoluteImageUrl('/a.jpg'), 'https://suh-project.synology.me/a.jpg');
    });

    test('http/https 절대 주소는 그대로', () {
      expect(AppUrls.toAbsoluteImageUrl('https://x/y'), 'https://x/y');
      expect(AppUrls.toAbsoluteImageUrl('http://x/y'), 'http://x/y');
    });

    test('빈 값은 빈 문자열', () {
      expect(AppUrls.toAbsoluteImageUrl(''), '');
    });
  });

  group('AppUrls.toWebSocketUrl', () {
    test('https > wss + /chat', () {
      expect(AppUrls.toWebSocketUrl('https://api.romrom.suhsaechan.kr'), 'wss://api.romrom.suhsaechan.kr/chat');
    });

    test('http > ws + /chat (포트 유지)', () {
      expect(AppUrls.toWebSocketUrl('http://h:8079'), 'ws://h:8079/chat');
    });

    test('끝 슬래시가 있어도 /chat 한 번만', () {
      expect(AppUrls.toWebSocketUrl('https://h/'), 'wss://h/chat');
    });
  });
}
