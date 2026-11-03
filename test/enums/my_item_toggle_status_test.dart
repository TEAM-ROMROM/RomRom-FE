import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/my_item_toggle_status.dart';

void main() {
  group('MyItemToggleStatus 빈 상태 문구', () {
    test('탭별 문구 구분 (교환 완료 탭은 등록 안내 대신 교환 완료 안내)', () {
      expect(MyItemToggleStatus.all.emptyItemsTitle, '등록된 물품이 없어요');
      expect(MyItemToggleStatus.selling.emptyItemsTitle, '교환 가능한 물품이 없어요');
      expect(MyItemToggleStatus.completed.emptyItemsTitle, '교환 완료된 물품이 없어요');
      expect(MyItemToggleStatus.selling.emptyItemsDescription, contains('등록'));
      expect(MyItemToggleStatus.completed.emptyItemsDescription, isNot(contains('등록')));
    });
  });
}
