import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/deep_link_route.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/utils/deep_link_router.dart';

/// 딥링크 경로 판정 + 공유 링크 내 물품 판정
void main() {
  group('RomRomDeepLinkRouter.resolveRoute', () {
    test('알려진 romrom 경로 > 각 화면', () {
      expect(RomRomDeepLinkRouter.resolveRoute(Uri.parse('romrom://item/detail?itemId=A')), DeepLinkRoute.itemDetail);
      expect(RomRomDeepLinkRouter.resolveRoute(Uri.parse('romrom://chat/room?chatRoomId=C')), DeepLinkRoute.chatRoom);
      expect(RomRomDeepLinkRouter.resolveRoute(Uri.parse('romrom://item/deleted')), DeepLinkRoute.itemDeleted);
      expect(
        RomRomDeepLinkRouter.resolveRoute(Uri.parse('romrom://notice/detail?announcementId=N')),
        DeepLinkRoute.noticeDetail,
      );
      expect(RomRomDeepLinkRouter.resolveRoute(Uri.parse('romrom://profile/reviews')), DeepLinkRoute.receivedReviews);
    });

    test('모르는 romrom 경로·필수 id 없음 > 알림함', () {
      expect(RomRomDeepLinkRouter.resolveRoute(Uri.parse('romrom://event/new')), DeepLinkRoute.notificationFallback);
      expect(RomRomDeepLinkRouter.resolveRoute(Uri.parse('romrom://item/detail')), DeepLinkRoute.notificationFallback);
      expect(RomRomDeepLinkRouter.resolveRoute(Uri.parse('romrom://chat/room')), DeepLinkRoute.notificationFallback);
      expect(
        RomRomDeepLinkRouter.resolveRoute(Uri.parse('romrom://notice/detail')),
        DeepLinkRoute.notificationFallback,
      );
    });

    test('공유 링크 > 공유 물품, 다른 도메인·경로 > 무시', () {
      expect(
        RomRomDeepLinkRouter.resolveRoute(Uri.parse('https://romrom-c4008.web.app/item?itemId=A')),
        DeepLinkRoute.sharedItem,
      );
      expect(RomRomDeepLinkRouter.resolveRoute(Uri.parse('https://romrom-c4008.web.app/item')), DeepLinkRoute.ignored);
      expect(RomRomDeepLinkRouter.resolveRoute(Uri.parse('https://romrom-c4008.web.app/about')), DeepLinkRoute.ignored);
      expect(RomRomDeepLinkRouter.resolveRoute(Uri.parse('https://example.com/item?itemId=A')), DeepLinkRoute.ignored);
    });
  });

  group('resolveItemAccessFlags', () {
    Item itemOf(String? authorMemberId, {String? itemStatus}) => Item(
      member: Member(memberId: authorMemberId),
      itemStatus: itemStatus,
    );

    test('내 물품 > 내 물품, 요청 버튼 없음', () async {
      final flags = await resolveItemAccessFlags(
        readItem: () async => itemOf('M1'),
        readCurrentMemberId: () async => 'M1',
      );
      expect(flags.isMyItem, isTrue);
      expect(flags.isTradeRequestAllowed, isFalse);
    });

    test('남의 판매 중 물품 > 요청 버튼', () async {
      final flags = await resolveItemAccessFlags(
        readItem: () async => itemOf('M2', itemStatus: ItemStatus.available.serverName),
        readCurrentMemberId: () async => 'M1',
      );
      expect(flags.isMyItem, isFalse);
      expect(flags.isTradeRequestAllowed, isTrue);
    });

    test('남의 교환 완료 물품 > 요청 버튼 없음', () async {
      final flags = await resolveItemAccessFlags(
        readItem: () async => itemOf('M2', itemStatus: ItemStatus.exchanged.serverName),
        readCurrentMemberId: () async => 'M1',
      );
      expect(flags.isTradeRequestAllowed, isFalse);
    });

    test('조회 실패·작성자 없음 > 판정 불가 (내 물품 아님, 요청 버튼 없음)', () async {
      for (final readItem in <Future<Item?> Function()>[() async => throw Exception('network'), () async => null]) {
        final flags = await resolveItemAccessFlags(readItem: readItem, readCurrentMemberId: () async => 'M1');
        expect(flags.isMyItem, isFalse);
        expect(flags.isTradeRequestAllowed, isFalse);
      }
    });
  });
}
