import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/navigation_tab_items.dart';
import 'package:romrom_fe/enums/notification_setting_type.dart';
import 'package:romrom_fe/enums/refresh_trigger.dart';
import 'package:romrom_fe/providers/chat_rooms_provider.dart';
import 'package:romrom_fe/providers/current_tab_index_provider.dart';
import 'package:romrom_fe/providers/home_feed_provider.dart';
import 'package:romrom_fe/providers/member_profile_provider.dart';
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/providers/notification_list_provider.dart';
import 'package:romrom_fe/providers/notification_setting_provider.dart';
import 'package:romrom_fe/providers/notification_unread_count_provider.dart';
import 'package:romrom_fe/providers/received_reviews_refresh_trigger_provider.dart';
import 'package:romrom_fe/providers/trade_requests_provider.dart';
import 'package:romrom_fe/services/firebase_service.dart';
import 'package:romrom_fe/services/foreground_push_refresher.dart';
import 'package:romrom_fe/screens/chat_tab_screen.dart';
import 'package:romrom_fe/services/notification_permission_service.dart';
import 'package:romrom_fe/screens/home_tab_screen.dart';
import 'package:romrom_fe/screens/my_page_tab_screen.dart';
import 'package:romrom_fe/screens/register_tab_screen.dart';
import 'package:romrom_fe/screens/request_management_tab_screen.dart';
import 'package:romrom_fe/services/heart_beat_manager.dart';
import 'package:romrom_fe/services/app_review_service.dart';
import 'package:romrom_fe/widgets/common/app_review_popup.dart';
import 'package:romrom_fe/widgets/common/lazy_indexed_stack.dart';
import 'package:romrom_fe/widgets/custom_bottom_navigation_bar.dart';
import 'package:romrom_fe/widgets/home_popup/home_popup_presenter.dart';

/// 메인 화면
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with WidgetsBindingObserver {
  // 시작 시 바로 만드는 탭: 홈(첫 화면), 채팅(웹소켓 방 구독으로 하단 탭 안 읽음 점 실시간 갱신)
  // 나머지(요청관리·등록·마이페이지)는 처음 누를 때 생성 > 첫 화면 요청 몰림 방지
  static final Set<int> _eagerTabIndices = {NavigationTabItems.home.index, NavigationTabItems.chat.index};

  final Set<String> _pendingRequests = <String>{};

  // 앱 사용 중 푸시 구독 (dispose에서 해제)
  StreamSubscription<RemoteMessage>? _foregroundPushSubscription;

  @override
  void initState() {
    super.initState();
    _listenForegroundPush();
    HeartbeatManager.instance.start();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _syncNotificationPermissionToBackend();
      await AppReviewService().onAppLaunch();
    });
  }

  /// 탭 index > 탭 화면 (LazyIndexedStack이 처음 필요할 때 1회 생성)
  Widget _buildTabScreen(BuildContext context, int tabIndex) {
    switch (NavigationTabItems.fromIndex(tabIndex)) {
      case NavigationTabItems.home:
        return HomeTabScreen(onLoaded: _onHomeLoaded);
      case NavigationTabItems.requestManagement:
        return const RequestManagementTabScreen();
      case NavigationTabItems.register:
        return const RegisterTabScreen();
      case NavigationTabItems.chat:
        return const ChatTabScreen();
      case NavigationTabItems.myPage:
        return const MyPageTabScreen();
    }
  }

  /// 홈 피드 첫 로딩 완료 시 공지·이벤트 팝업 (#652)
  Future<void> _onHomeLoaded() async {
    if (!mounted) return;
    await HomePopupPresenter.showIfNeeded(context, ref);
  }

  /// 시스템 알림 권한이 거부된 경우 백엔드 설정과 동기화
  /// - 시스템 거부 → 백엔드 5개 항목 전체 false (미결정은 유지)
  Future<void> _syncNotificationPermissionToBackend() async {
    const requestKey = 'sync_notification_permission';
    if (_pendingRequests.contains(requestKey)) return;
    _pendingRequests.add(requestKey);
    // await 이후 ref 사용 방지 (notifier 선확보)
    final memberProfileNotifier = ref.read(memberProfileProvider.notifier);
    final notificationSettingNotifier = ref.read(notificationSettingProvider.notifier);
    try {
      // 거부한 경우만 동기화 (미결정 = 아직 안내 전 > 서버 설정 유지)
      final bool isPermissionDeclined = await NotificationPermissionService().isPermissionDeclined();
      if (!isPermissionDeclined) return;

      // 공유 회원 프로필 (알림 설정 변경 시 notificationSettingProvider가 무효화)
      final memberProfile = await memberProfileNotifier.fetchCachedOrReload();
      final member = memberProfile.member;
      if (member == null) return;

      final bool anyEnabled =
          (member.isMarketingInfoAgreed ?? false) ||
          (member.isActivityNotificationAgreed ?? false) ||
          (member.isChatNotificationAgreed ?? false) ||
          (member.isContentNotificationAgreed ?? false) ||
          (member.isTradeNotificationAgreed ?? false);

      if (anyEnabled) {
        // 5개 항목 전체 false: notificationSettingProvider 일괄 요청 1회 (백그라운드라 실패 스낵바 없음)
        final isSyncSucceeded = await notificationSettingNotifier.setAll({
          for (final settingType in NotificationSettingType.values) settingType: false,
        }, isSilent: true);
        if (isSyncSucceeded) {
          debugPrint('[알림 동기화] 시스템 권한 거부 → 백엔드 알림 설정 전체 false 반영');
        } else {
          debugPrint('[알림 동기화] 실패: 일괄 변경 미반영 (다음 앱 복귀 시 재시도)');
        }
      }
    } catch (e) {
      debugPrint('[알림 동기화] 실패: $e');
    } finally {
      _pendingRequests.remove(requestKey);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 비활성·백그라운드·종료 직전: 홈 피드 본 물품 기록 즉시 저장 (묶음 저장 대기분 유실 방지)
    if (state != AppLifecycleState.resumed) {
      _flushHomeFeedSeenItems();
      return;
    }
    _syncNotificationPermissionToBackend();
    _tryShowReviewPopup();
    // 현재 탭이 홈이면 피드 자동 새로고침 (throttle 적용)
    final currentTab = ref.read(currentTabIndexProvider);
    if (currentTab == 0) {
      ref.read(homeFeedProvider.notifier).refresh(trigger: RefreshTrigger.foregroundResume);
    }
  }

  /// 앱 복귀 시 리뷰 팝업 조건 체크 (iOS/Android 공통)
  Future<void> _tryShowReviewPopup() async {
    final service = AppReviewService();
    if (await service.shouldShow(tradeTriggered: false)) {
      if (mounted) await AppReviewPopup.show(context, service);
    }
  }

  @override
  void dispose() {
    _foregroundPushSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 홈 피드 본 물품 기록 즉시 저장 (피드 아직 없으면 저장할 것 없음)
  void _flushHomeFeedSeenItems() {
    if (!ref.exists(homeFeedProvider)) return;
    unawaited(ref.read(homeFeedProvider.notifier).flushSeenItemIds());
  }

  /// 앱 사용 중 푸시 > 종류별 상태 재조회 (알림 목록·배지, 받은·보낸 요청, 내 물품, 채팅방, 받은 후기) (#964, #1007)
  /// 아직 만든 적 없는 provider(알림 화면·요청관리 탭 미방문)는 건너뜀 > 처음 볼 때 새로 조회 (배지는 미확인 수만)
  void _listenForegroundPush() {
    // 호출 시점에 notifier를 읽음 (세션 초기화 뒤에도 최신 인스턴스 사용)
    final foregroundPushRefresher = ForegroundPushRefresher(
      reloadNotificationList: () => ref.exists(notificationListProvider)
          ? ref.read(notificationListProvider.notifier).reload()
          : _refreshNotificationUnreadCount(),
      refreshNotificationUnreadCount: () => ref.exists(notificationListProvider)
          ? ref.read(notificationListProvider.notifier).refreshUnreadCount()
          : _refreshNotificationUnreadCount(),
      reloadReceivedTradeRequests: () async {
        if (!ref.exists(tradeRequestsProvider)) return;
        await ref.read(tradeRequestsProvider.notifier).reloadReceivedOfRequestedCard();
      },
      reloadMyItems: () => ref.read(myItemsProvider.notifier).reload(),
      reloadSentTradeRequests: () async {
        if (!ref.exists(tradeRequestsProvider)) return;
        await ref.read(tradeRequestsProvider.notifier).reloadSent();
      },
      reloadChatRooms: () async {
        if (!ref.exists(chatRoomsProvider)) return;
        await ref.read(chatRoomsProvider.notifier).refreshFirstPage();
      },
      reloadReceivedReviews: () async => ref.read(receivedReviewsRefreshTriggerProvider.notifier).requestRefresh(),
    );
    _foregroundPushSubscription = FirebaseService().onForegroundMessage.listen(
      (message) => foregroundPushRefresher.onForegroundPush(message.data),
    );
  }

  /// 홈 알림 배지 미확인 수만 재조회 (결과는 provider가 보관)
  Future<void> _refreshNotificationUnreadCount() async {
    await ref.read(notificationUnreadCountProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(currentTabIndexProvider);

    // 홈 탭을 떠날 때 본 물품 기록 즉시 저장 (탭 재진입 새로고침 없음 > 다녀와도 보던 카드 유지)
    ref.listen<int>(currentTabIndexProvider, (previousTabIndex, nextTabIndex) {
      final isLeavingHomeTab =
          previousTabIndex == NavigationTabItems.home.index && nextTabIndex != NavigationTabItems.home.index;
      if (isLeavingHomeTab) _flushHomeFeedSeenItems();
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBody: false,
      body: LazyIndexedStack(
        index: tabIndex,
        itemCount: NavigationTabItems.values.length,
        eagerIndices: _eagerTabIndices,
        itemBuilder: _buildTabScreen,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: tabIndex,
        onTap: (index) {
          ref.read(currentTabIndexProvider.notifier).set(index);
        },
      ),
    );
  }
}
