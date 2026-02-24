import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:romrom_fe/enums/notification_type.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/screens/chat_room_screen.dart';

class RomRomDeepLinkRouter {
  static Future<void> open(BuildContext context, String? deepLink, {NotificationType? notificationType}) async {
    if (deepLink == null || deepLink.trim().isEmpty) return;

    final uri = Uri.tryParse(deepLink);
    if (uri == null) return;
    if (uri.scheme != 'romrom') return;

    final routeKey = '${uri.host}${uri.path}';

    switch (routeKey) {
      case 'item/detail':
        {
          final itemId = uri.queryParameters['itemId'];
          final tradeRequestHistoryId = uri.queryParameters['tradeRequestHistoryId'];
          if (itemId == null || itemId.isEmpty) return;

          final (isMyItem, isRequestManagement, isChatAccessAllowed) = _resolveItemFlags(notificationType);

          final imageSize = Size(MediaQuery.of(context).size.width, 400.h);

          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ItemDetailDescriptionScreen(
                itemId: itemId,
                imageSize: imageSize,
                currentImageIndex: 0,
                heroTag: 'deeplink_item_$itemId',
                isMyItem: isMyItem,
                isRequestManagement: isRequestManagement,
                isChatAccessAllowed: isChatAccessAllowed,
                tradeRequestHistoryId: tradeRequestHistoryId,
              ),
            ),
          );
          return;
        }

      case 'chat/room':
        {
          final chatRoomId = uri.queryParameters['chatRoomId'];
          if (chatRoomId == null || chatRoomId.isEmpty) return;

          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatRoomScreen(chatRoomId: chatRoomId)));
          return;
        }

      default:
        return;
    }
  }

  static (bool, bool, bool) _resolveItemFlags(NotificationType? type) {
    switch (type) {
      // 내 물품
      case NotificationType.itemLiked:
        return (true, false, false);
      // 상대 물품, 받은 요청
      case NotificationType.tradeRequestReceived:
        return (false, true, true);
      default:
        return (false, false, false);
    }
  }
}
