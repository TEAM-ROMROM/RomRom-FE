import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/request_management_item_card.dart';

/// 요청관리 카드 카테고리: 아는 값은 표시 이름, 모르는·없는 값은 '기타'
void main() {
  test('fromItem > 카테고리 표시 이름, 모르는·없는 카테고리는 기타', () {
    expect(RequestManagementItemCard.fromItem(Item(itemCategory: 'SHOES')).category, '신발');
    expect(RequestManagementItemCard.fromItem(Item(itemCategory: 'NEW_CATEGORY')).category, '기타');
    expect(RequestManagementItemCard.fromItem(Item()).category, '기타');
  });

  test('fromItem > 이름 없음은 기본 공백, titleFallback 지정 시 그 값', () {
    expect(RequestManagementItemCard.fromItem(Item()).title, ' ');
    expect(RequestManagementItemCard.fromItem(Item(), titleFallback: '').title, '');
    expect(RequestManagementItemCard.fromItem(Item(), titleFallback: '물품').title, '물품');
    expect(RequestManagementItemCard.fromItem(Item(itemName: '시계'), titleFallback: '물품').title, '시계');
  });

  test('fromItem > itemId 없어도 크래시 없이 빈 문자열', () {
    expect(RequestManagementItemCard.fromItem(Item()).itemId, '');
    expect(RequestManagementItemCard.fromItem(Item(itemId: 'a1')).itemId, 'a1');
  });
}
