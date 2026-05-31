import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/providers/current_tab_index_provider.dart';
import 'package:romrom_fe/screens/chat_tab_screen.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/services/notification_permission_service.dart';
import 'package:romrom_fe/widgets/common/notification_bottom_sheet.dart';
import 'package:romrom_fe/screens/home_tab_screen.dart';
import 'package:romrom_fe/screens/my_page_tab_screen.dart';
import 'package:romrom_fe/screens/register_tab_screen.dart';
import 'package:romrom_fe/screens/request_management_tab_screen.dart';
import 'package:romrom_fe/services/heart_beat_manager.dart';
import 'package:romrom_fe/services/app_review_service.dart';
import 'package:romrom_fe/widgets/common/app_review_popup.dart';
import 'package:romrom_fe/widgets/custom_bottom_navigation_bar.dart';

/// 메인 화면
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with WidgetsBindingObserver {
  late final List<Widget> _navigationTabScreens;
  final Set<String> _pendingRequests = <String>{};

  @override
  void initState() {
    super.initState();
    _navigationTabScreens = [
      HomeTabScreen(onLoaded: _onHomeLoaded),
      const RequestManagementTabScreen(),
      const RegisterTabScreen(),
      const ChatTabScreen(),
      const MyPageTabScreen(),
    ];
    HeartbeatManager.instance.start();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _syncNotificationPermissionToBackend();
      await AppReviewService().onAppLaunch();
    });
  }

  /// 홈 피드 로딩 완료 시 호출 — 바텀시트는 홈이 그려진 후 표시
  /// 알림 권한 OFF인 경우에만 표시:
  ///   1) 회원가입 후 최초 1회 → showNotificationBottomSheetAfterSiginIn
  ///   2) 이후 7일 주기 → showdNotificationBottomSheetCycle
  Future<void> _onHomeLoaded() async {
    if (!mounted) return;
    final service = NotificationPermissionService();

    // 회원가입 최초 1회 (권한 OFF + 미노출 시에만)
    if (await service.shouldShowBottomSheet(isSignup: true)) {
      if (mounted) await NotificationBottomSheet.showNotificationBottomSheetAfterSiginIn(context);
      await service.markShownOnSignup();
      return; // 동일 세션에서 7일 주기 바텀시트 중복 노출 방지
    }

    // 7일 주기 (권한 OFF인 경우에만)
    if (await service.shouldShowBottomSheet()) {
      if (mounted) await NotificationBottomSheet.showdNotificationBottomSheetCycle(context);
    }
  }

  /// 시스템 알림 권한이 거부된 경우 백엔드 설정과 동기화
  /// - 시스템 OFF → 백엔드 5개 항목 전체 false
  Future<void> _syncNotificationPermissionToBackend() async {
    const requestKey = 'sync_notification_permission';
    if (_pendingRequests.contains(requestKey)) return;
    _pendingRequests.add(requestKey);
    try {
      final bool permissionGranted = await NotificationPermissionService().isPermissionGranted();
      if (permissionGranted) return;

      final memberResponse = await MemberApi().getMemberInfo();
      final member = memberResponse.member;
      if (member == null) return;

      final bool anyEnabled =
          (member.isMarketingInfoAgreed ?? false) ||
          (member.isActivityNotificationAgreed ?? false) ||
          (member.isChatNotificationAgreed ?? false) ||
          (member.isContentNotificationAgreed ?? false) ||
          (member.isTradeNotificationAgreed ?? false);

      if (anyEnabled) {
        await MemberApi().updateNotificationSetting(
          isMarketingInfoAgreed: false,
          isActivityNotificationAgreed: false,
          isChatNotificationAgreed: false,
          isContentNotificationAgreed: false,
          isTradeNotificationAgreed: false,
        );
        debugPrint('[알림 동기화] 시스템 권한 거부 → 백엔드 알림 설정 전체 false 반영');
      }
    } catch (e) {
      debugPrint('[알림 동기화] 실패: $e');
    } finally {
      _pendingRequests.remove(requestKey);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncNotificationPermissionToBackend();
      _tryShowReviewPopup();
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(currentTabIndexProvider);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBody: false,
      body: IndexedStack(index: tabIndex, children: _navigationTabScreens),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: tabIndex,
        onTap: (index) {
          ref.read(currentTabIndexProvider.notifier).set(index);
        },
      ),
    );
  }
}
