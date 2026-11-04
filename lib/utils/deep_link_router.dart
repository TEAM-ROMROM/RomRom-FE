import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:romrom_fe/enums/deep_link_route.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/enums/notification_type.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/models/pending_deep_link.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/providers/open_chat_room_registry_provider.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/screens/chat_room_screen.dart';
import 'package:romrom_fe/screens/item_deleted_screen.dart';
import 'package:romrom_fe/screens/notice_detail_screen.dart';
import 'package:romrom_fe/screens/notification_screen.dart';
import 'package:romrom_fe/screens/profile/member_profile_screen.dart';
import 'package:romrom_fe/services/deep_link_gate.dart';
import 'package:romrom_fe/services/forced_update_lock.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';

/// 물품 접근 판정 결과: 내 물품 여부, 교환 요청 버튼 표시 여부
typedef ItemAccessFlags = ({bool isMyItem, bool isTradeRequestAllowed});

/// 물품 조회 > 작성자 <-> 현재 회원, 거래 상태로 판정
/// 조회 실패·작성자 없음 > 판정 불가 (내 물품 아님, 요청 버튼 숨김 — 상세 화면이 자체 오류 처리)
Future<ItemAccessFlags> resolveItemAccessFlags({
  required Future<Item?> Function() readItem,
  required Future<String?> Function() readCurrentMemberId,
}) async {
  const unresolvedFlags = (isMyItem: false, isTradeRequestAllowed: false);
  try {
    final linkedItem = await readItem();
    final authorMemberId = linkedItem?.member?.memberId;
    if (linkedItem == null || authorMemberId == null) return unresolvedFlags;
    if (authorMemberId == await readCurrentMemberId()) return (isMyItem: true, isTradeRequestAllowed: false);
    final isExchanged = linkedItem.itemStatus == ItemStatus.exchanged.serverName;
    return (isMyItem: false, isTradeRequestAllowed: !isExchanged);
  } catch (error) {
    debugPrint('[deep link] item access check failed : $error');
    return unresolvedFlags;
  }
}

/// 딥링크 라우터: 진입 게이트 경유(수신·메인 진입) > 경로 판정 > 화면 이동
class RomRomDeepLinkRouter {
  // 공유 링크 도메인 (AppUrls.itemShareBaseUrl 단일 원본)
  static final String _sharedLinkHost = Uri.parse(AppUrls.itemShareBaseUrl).host;

  /// 링크 수신 (푸시 탭·앱 링크): 강제 업데이트 표시 중이면 폐기, 메인 진입 전이면 게이트에 보관, 진입 후면 바로 열기
  static void receive(PendingDeepLink deepLink) {
    if (_isBlockedByForcedUpdate()) return;
    final deepLinkToOpen = DeepLinkGate.instance.receive(deepLink);
    if (deepLinkToOpen == null) return;
    final navigatorContext = navigatorKey.currentContext;
    if (navigatorContext == null || !navigatorContext.mounted) return;
    openFromUri(
      navigatorContext,
      deepLinkToOpen.uri,
      notificationType: deepLinkToOpen.notificationType,
      extraData: deepLinkToOpen.extraData,
    );
  }

  /// 메인 화면 진입 (스플래시·로그인·온보딩 완료): 게이트 열기 > 보관 링크는 화면 전환 다음 프레임에 열기
  static void onMainScreenEntered() {
    final pendingDeepLink = DeepLinkGate.instance.enterMainScreen();
    if (pendingDeepLink == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 프레임 사이 세션 종료·강제 업데이트 > 열지 않음
      if (!DeepLinkGate.instance.isMainScreenEntered || _isBlockedByForcedUpdate()) return;
      final navigatorContext = navigatorKey.currentContext;
      if (navigatorContext == null || !navigatorContext.mounted) return;
      openFromUri(
        navigatorContext,
        pendingDeepLink.uri,
        notificationType: pendingDeepLink.notificationType,
        extraData: pendingDeepLink.extraData,
      );
    });
    // 다음 프레임 보장 (화면 전환이 없는 호출에서도 보관 링크 열기)
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// 강제 업데이트 화면 표시 중 > 링크 이동 차단 (업데이트 화면 위 화면 쌓임 방지, 앱 종료까지 유지라 보관 없이 폐기)
  static bool _isBlockedByForcedUpdate() {
    if (!ForcedUpdateLock.instance.isForcedUpdateShowing) return false;
    debugPrint('[deep link] dropped : forced update showing');
    return true;
  }

  /// 문자열 딥링크 열기 (알림함 탭 등), [isNotificationFallbackEnabled] false면 모르는 경로 무시
  static Future<void> open(
    BuildContext context,
    String? deepLink, {
    NotificationType? notificationType,
    Map<String, dynamic>? extraData,
    bool isNotificationFallbackEnabled = true,
  }) async {
    if (deepLink == null || deepLink.trim().isEmpty) return;

    final uri = Uri.tryParse(deepLink);
    if (uri == null) return;

    await openFromUri(
      context,
      uri,
      notificationType: notificationType,
      extraData: extraData,
      isNotificationFallbackEnabled: isNotificationFallbackEnabled,
    );
  }

  /// 주소 > 이동 대상 (romrom 스킴: 알려진 경로·필수 id 확인, https: 공유 도메인 물품 링크만)
  static DeepLinkRoute resolveRoute(Uri uri) {
    if (uri.scheme == 'romrom') return _resolveRomRomRoute(uri);
    final isSharedItemLink =
        uri.scheme == 'https' && uri.host == _sharedLinkHost && uri.path == '/item' && _hasQuery(uri, 'itemId');
    return isSharedItemLink ? DeepLinkRoute.sharedItem : DeepLinkRoute.ignored;
  }

  static DeepLinkRoute _resolveRomRomRoute(Uri uri) {
    switch ('${uri.host}${uri.path}') {
      case 'item/detail':
        return _hasQuery(uri, 'itemId') ? DeepLinkRoute.itemDetail : DeepLinkRoute.notificationFallback;
      case 'chat/room':
        return _hasQuery(uri, 'chatRoomId') ? DeepLinkRoute.chatRoom : DeepLinkRoute.notificationFallback;
      case 'item/deleted':
        return DeepLinkRoute.itemDeleted;
      case 'notice/detail':
        return _hasQuery(uri, 'announcementId') ? DeepLinkRoute.noticeDetail : DeepLinkRoute.notificationFallback;
      case 'profile/reviews':
        return DeepLinkRoute.receivedReviews;
      default:
        return DeepLinkRoute.notificationFallback;
    }
  }

  static bool _hasQuery(Uri uri, String key) => uri.queryParameters[key]?.isNotEmpty ?? false;

  /// 주소 > 이동 대상 판정 > 화면 이동 (모르는 경로는 알림함, 알림함 안에서 열 때는 끔)
  static Future<void> openFromUri(
    BuildContext context,
    Uri uri, {
    NotificationType? notificationType,
    Map<String, dynamic>? extraData,
    bool isNotificationFallbackEnabled = true,
  }) async {
    switch (resolveRoute(uri)) {
      case DeepLinkRoute.itemDetail:
        await _openItemDetail(
          context,
          itemId: uri.queryParameters['itemId']!,
          tradeRequestHistoryId: uri.queryParameters['tradeRequestHistoryId'],
          notificationType: notificationType,
          heroTag: 'deeplink_item_${uri.queryParameters['itemId']}',
        );
      case DeepLinkRoute.sharedItem:
        await _openItemDetail(
          context,
          itemId: uri.queryParameters['itemId']!,
          heroTag: 'share_item_${uri.queryParameters['itemId']}',
        );
      case DeepLinkRoute.chatRoom:
        await _openChatRoom(context, chatRoomId: uri.queryParameters['chatRoomId']!);
      case DeepLinkRoute.itemDeleted:
        // 게시글 삭제 제재 안내. 표시값은 FCM data·알림 payload에서 읽음 (한글 쿼리 인코딩 회피)
        await context.navigateTo(
          screen: ItemDeletedScreen(
            itemTitle: extraData?['itemName'] as String? ?? '',
            deleteReason: extraData?['deleteReason'] as String? ?? '',
          ),
        );
      case DeepLinkRoute.noticeDetail:
        await context.navigateTo(screen: NoticeDetailScreen(announcementId: uri.queryParameters['announcementId']!));
      case DeepLinkRoute.receivedReviews:
        await _openMyProfile(context);
      case DeepLinkRoute.notificationFallback:
        debugPrint('[deep link] unknown route : ${uri.host}${uri.path} (fallback: $isNotificationFallbackEnabled)');
        if (isNotificationFallbackEnabled) await context.navigateTo(screen: const NotificationScreen());
      case DeepLinkRoute.ignored:
        return;
    }
  }

  /// 내 프로필(받은 후기 포함) 이동 (회원 id 없음 > 이동 없음)
  static Future<void> _openMyProfile(BuildContext context) async {
    final currentMemberId = await UserInfo().getCurrentMemberId();
    if (currentMemberId == null || !context.mounted) return;
    await context.navigateTo(screen: MemberProfileScreen(memberId: currentMemberId));
  }

  /// 채팅방 이동: 같은 방이 맨 위에 보이면 그대로 둠 (그 방 푸시 배너 탭 > 같은 방 겹침 방지)
  static Future<void> _openChatRoom(BuildContext context, {required String chatRoomId}) async {
    final openChatRoomRegistry = ProviderScope.containerOf(context, listen: false).read(openChatRoomRegistryProvider);
    if (openChatRoomRegistry.isShowingOnTop(chatRoomId)) {
      debugPrint('[deep link] chat room already on top : skip push');
      return;
    }
    await context.navigateTo(screen: ChatRoomScreen(chatRoomId: chatRoomId));
  }

  /// 물품 상세 이동: 알림 타입으로 판정 가능하면 그 값, 아니면 물품 조회로 판정 (조회 중 로딩 표시)
  static Future<void> _openItemDetail(
    BuildContext context, {
    required String itemId,
    required String heroTag,
    String? tradeRequestHistoryId,
    NotificationType? notificationType,
  }) async {
    final notificationFlags = _resolveItemFlags(notificationType);
    final (isMyItem, isRequestManagement, isChatAccessAllowed, isTradeRequestAllowed) = notificationFlags != null
        ? (notificationFlags.$1, notificationFlags.$2, notificationFlags.$3, false)
        : await _resolveFlagsFromItem(context, itemId);
    if (!context.mounted) return;

    final imageSize = Size(MediaQuery.of(context).size.width, 400.h);
    await context.navigateTo(
      screen: ItemDetailDescriptionScreen(
        itemId: itemId,
        imageSize: imageSize,
        currentImageIndex: 0,
        heroTag: heroTag,
        isMyItem: isMyItem,
        isRequestManagement: isRequestManagement,
        isChatAccessAllowed: isChatAccessAllowed,
        isTradeRequestAllowed: isTradeRequestAllowed,
        tradeRequestHistoryId: tradeRequestHistoryId,
      ),
    );
  }

  /// 물품 조회로 판정 > (내 물품, 요청관리 아님, 채팅 없음, 요청 버튼)
  /// 상세 화면(#969 담당)은 자체 조회라 결과 재사용 불가 > 조회 중 화면 전체 로딩 표시로 무반응 대기 방지
  static Future<(bool, bool, bool, bool)> _resolveFlagsFromItem(BuildContext context, String itemId) async {
    final itemRepository = ProviderScope.containerOf(context, listen: false).read(itemRepositoryProvider);
    final loadingOverlay = _showLoadingOverlay(context);
    try {
      final flags = await resolveItemAccessFlags(
        readItem: () async => (await itemRepository.getItemDetail(itemId)).item,
        readCurrentMemberId: UserInfo().getCurrentMemberId,
      );
      return (flags.isMyItem, false, false, flags.isTradeRequestAllowed);
    } finally {
      // (성공·실패 공통)
      loadingOverlay?.remove();
    }
  }

  /// 루트 오버레이에 터치 차단 + 로딩 표시 (화면 스택 변화 없음, 제거는 호출부)
  static OverlayEntry? _showLoadingOverlay(BuildContext context) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return null;
    final overlayEntry = OverlayEntry(
      builder: (_) => const ColoredBox(
        color: AppColors.opacity50Black,
        child: Center(child: CommonLoadingIndicator()),
      ),
    );
    overlay.insert(overlayEntry);
    return overlayEntry;
  }

  /// 알림 타입 > (내 물품, 요청관리 진입, 채팅 허용), 판정 불가 타입은 null
  static (bool, bool, bool)? _resolveItemFlags(NotificationType? type) {
    switch (type) {
      // 내 물품
      case NotificationType.itemLiked:
        return (true, false, false);
      // 상대 물품, 받은 요청
      case NotificationType.tradeRequestReceived:
        return (false, true, true);
      default:
        return null;
    }
  }
}
