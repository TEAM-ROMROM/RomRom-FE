import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/widgets/home_feed_item_widget.dart';

void main() {
  group('HomeFeedItemWidget.toRegisterPromptMessage', () {
    test('교환 완료 물품만 있음 > 교환 가능한 물품 없음 안내', () {
      expect(HomeFeedItemWidget.toRegisterPromptMessage(hasExchangedItems: true), '교환 가능한 물품이 없어요\n새 물품을 등록해 주세요!');
    });

    test('등록 이력 없음 > 첫 등록 안내', () {
      expect(HomeFeedItemWidget.toRegisterPromptMessage(hasExchangedItems: false), '교환을 시작하려면\n먼저 나의 물품을 등록해 주세요!');
    });
  });
}
