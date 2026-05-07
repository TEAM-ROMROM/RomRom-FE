import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:romrom_fe/enums/notification_type.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/screens/chat_room_screen.dart';

/// 콜드 스타트 딥링크 대기 데이터 (FCM / app_links 공용)
///
/// 앱 종료 상태에서 알림/링크로 진입 시 SplashScreen 내비게이션이 완료된 후
/// 딥링크 화면으로 이동하기 위해 임시 저장한다.
class ColdStartDeepLinkData {
  static Uri? _pendingUri;
  static NotificationType? _pendingNotificationType;

  static bool get hasPending => _pendingUri != null;
  static Uri? get pendingUri => _pendingUri;
  static NotificationType? get pendingNotificationType => _pendingNotificationType;

  static void setPending(Uri uri, {NotificationType? notificationType}) {
    if (_pendingUri != null && notificationType == null) {
      return; // 이미 딥링크가 존재하는데 알림이 아닌 링크가 들어온 경우 무시 (알림 > 일반 링크 우선순위)
    }
    _pendingUri = uri;
    _pendingNotificationType = notificationType ?? _pendingNotificationType; // 알림이 없는 경우 기존 알림 타입 유지
  }

  static void clear() {
    _pendingUri = null;
    _pendingNotificationType = null;
  }
}

class RomRomDeepLinkRouter {
  static const String _hostingDomain = 'romrom-c4008.web.app';

  static Future<void> open(BuildContext context, String? deepLink, {NotificationType? notificationType}) async {
    if (deepLink == null || deepLink.trim().isEmpty) return;

    final uri = Uri.tryParse(deepLink);
    if (uri == null) return;

    await openFromUri(context, uri, notificationType: notificationType);
  }

  static Future<void> openFromUri(BuildContext context, Uri uri, {NotificationType? notificationType}) async {
    if (uri.scheme == 'romrom') {
      await _openRomRomScheme(context, uri, notificationType: notificationType);
    } else if (uri.scheme == 'https' && uri.host == _hostingDomain) {
      await _openHttpsLink(context, uri);
    }
  }

  static Future<void> _openHttpsLink(BuildContext context, Uri uri) async {
    // https://romrom-c4008.web.app/item?itemId=XXX
    if (uri.path == '/item') {
      final itemId = uri.queryParameters['itemId'];
      if (itemId == null || itemId.isEmpty) return;

      final imageSize = Size(MediaQuery.of(context).size.width, 400.h);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ItemDetailDescriptionScreen(
            itemId: itemId,
            imageSize: imageSize,
            currentImageIndex: 0,
            heroTag: 'share_item_$itemId',
            isMyItem: false,
            isRequestManagement: false,
          ),
        ),
      );
    }
  }

  static Future<void> _openRomRomScheme(BuildContext context, Uri uri, {NotificationType? notificationType}) async {
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
