import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/account_status.dart';
import 'package:romrom_fe/enums/chat_room_type.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_sort_field.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/enums/my_item_toggle_status.dart';
import 'package:romrom_fe/enums/notification_type.dart';
import 'package:romrom_fe/enums/trade_status.dart';

/// 서버 문자열 > enum 조회: 아는 값은 해당 값, 모르는 값·null 은 예외 없이 null
void main() {
  const unknownServerName = 'BRAND_NEW_SERVER_VALUE';

  group('fromServerName', () {
    test('ItemCondition', () {
      expect(ItemCondition.fromServerName('SEALED'), ItemCondition.sealed);
      expect(ItemCondition.fromServerName('HEAVILY_USED'), ItemCondition.heavilyUsed);
      expect(ItemCondition.fromServerName(unknownServerName), isNull);
      expect(ItemCondition.fromServerName(null), isNull);
    });

    test('TradeStatus', () {
      expect(TradeStatus.fromServerName('TRADED'), TradeStatus.traded);
      expect(TradeStatus.fromServerName(unknownServerName), isNull);
      expect(TradeStatus.fromServerName(null), isNull);
    });

    test('ItemCategories', () {
      expect(ItemCategories.fromServerName('OTHER'), ItemCategories.etc);
      expect(ItemCategories.fromServerName(unknownServerName), isNull);
      expect(ItemCategories.fromServerName(''), isNull);
      expect(ItemCategories.fromServerName(null), isNull);
    });

    test('NotificationType', () {
      expect(NotificationType.fromServerName('ITEM_LIKED'), NotificationType.itemLiked);
      // BE NotificationType.ANNOUNCEMENT (옛 값 SYSTEM_NOTICE는 BE에 없음, #942)
      expect(NotificationType.fromServerName('ANNOUNCEMENT'), NotificationType.announcement);
      expect(NotificationType.fromServerName('SYSTEM_NOTICE'), isNull);
      expect(NotificationType.fromServerName(unknownServerName), isNull);
      expect(NotificationType.fromServerName(null), isNull);
    });

    test('ItemTradeOption', () {
      expect(ItemTradeOption.fromServerName('DELIVERY_ONLY'), ItemTradeOption.deliveryOnly);
      expect(ItemTradeOption.fromServerName(unknownServerName), isNull);
      expect(ItemTradeOption.fromServerName(null), isNull);
    });

    test('ItemStatus', () {
      expect(ItemStatus.fromServerName('EXCHANGED'), ItemStatus.exchanged);
      expect(ItemStatus.fromServerName(unknownServerName), isNull);
      expect(ItemStatus.fromServerName(null), isNull);
    });

    test('MyItemToggleStatus', () {
      expect(MyItemToggleStatus.fromServerName('AVAILABLE'), MyItemToggleStatus.selling);
      expect(MyItemToggleStatus.fromServerName(unknownServerName), isNull);
      expect(MyItemToggleStatus.fromServerName(null), isNull);
    });

    test('ItemSortField', () {
      expect(ItemSortField.fromServerName('DISTANCE'), ItemSortField.distance);
      expect(ItemSortField.fromServerName(unknownServerName), isNull);
      expect(ItemSortField.fromServerName(null), isNull);
    });

    test('AccountStatus', () {
      expect(AccountStatusExtension.fromServerName('DELETE_ACCOUNT'), AccountStatus.deleteAccount);
      expect(AccountStatusExtension.fromServerName(unknownServerName), isNull);
      expect(AccountStatusExtension.fromServerName(null), isNull);
    });

    test('ChatRoomType', () {
      expect(ChatRoomTypeExtension.fromServerName('RECEIVED'), ChatRoomType.received);
      expect(ChatRoomTypeExtension.fromServerName(unknownServerName), isNull);
      expect(ChatRoomTypeExtension.fromServerName(null), isNull);
    });
  });
}
