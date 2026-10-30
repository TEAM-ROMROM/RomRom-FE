import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/home_popup_link_opener.dart';

void main() {
  test('romrom:// 딥링크·http(s):// > 이동 가능', () {
    expect(isOpenableHomePopupLink('romrom://item/detail?itemId=item-1'), isTrue);
    expect(isOpenableHomePopupLink('https://romrom.example.com/event'), isTrue);
    expect(isOpenableHomePopupLink('http://romrom.example.com/event'), isTrue);
  });

  test('누락·지원 안 하는 스킴·호스트 없음 > 이동 불가', () {
    expect(isOpenableHomePopupLink(null), isFalse);
    expect(isOpenableHomePopupLink(''), isFalse);
    expect(isOpenableHomePopupLink('ftp://files.example.com/a'), isFalse);
    expect(isOpenableHomePopupLink('javascript:alert(1)'), isFalse);
    expect(isOpenableHomePopupLink('event-page'), isFalse);
  });
}
