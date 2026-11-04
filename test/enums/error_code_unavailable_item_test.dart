import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/error_code.dart';

void main() {
  group('ErrorCode.isUnavailableItemError', () {
    test('볼 수 없는 물품 오류 5종은 true', () {
      const unavailableItemErrorCodes = [
        ErrorCode.deletedMember,
        ErrorCode.suspendedMember,
        ErrorCode.deletedItem,
        ErrorCode.itemNotFound,
        ErrorCode.itemAdminHidden,
      ];
      for (final errorCode in unavailableItemErrorCodes) {
        expect(errorCode.isUnavailableItemError, isTrue, reason: errorCode.name);
      }
    });

    test('그 외 코드는 false', () {
      expect(ErrorCode.alreadyHiddenItem.isUnavailableItemError, isFalse);
      expect(ErrorCode.unknown.isUnavailableItemError, isFalse);
    });

    test('서버 코드 문자열 ITEM_ADMIN_HIDDEN은 itemAdminHidden으로 변환', () {
      expect(ErrorCode.fromCode('ITEM_ADMIN_HIDDEN'), ErrorCode.itemAdminHidden);
    });
  });
}
