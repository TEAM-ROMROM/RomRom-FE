import 'package:flutter/material.dart';
import 'package:romrom_fe/screens/chat_tab_screen.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/services/notification_permission_service.dart';
import 'package:romrom_fe/widgets/common/notification_bottom_sheet.dart';
import 'package:romrom_fe/screens/home_tab_screen.dart';
import 'package:romrom_fe/screens/my_page_tab_screen.dart';
import 'package:romrom_fe/screens/register_tab_screen.dart';
import 'package:romrom_fe/screens/request_management_tab_screen.dart';
import 'package:romrom_fe/services/heart_beat_manager.dart';
import 'package:romrom_fe/widgets/custom_bottom_navigation_bar.dart';

/// 메인 화면
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  // MainScreen의 상태에 접근하기 위한 GlobalKey
  static final GlobalKey<State<MainScreen>> globalKey = GlobalKey<State<MainScreen>>();

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentTabIndex = 0; // 선택된 탭 인덱스 관리
  late final List<Widget> _navigationTabScreens;
  final Set<String> _pendingRequests = <String>{};

  @override
  void initState() {
    super.initState();
    _navigationTabScreens = [
      HomeTabScreen(key: HomeTabScreen.globalKey, onLoaded: _onHomeLoaded),
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

  /// 외부에서 탭을 전환할 수 있는 메서드
  void switchToTab(int index) {
    if (index >= 0 && index < _navigationTabScreens.length) {
      setState(() {
        _currentTabIndex = index;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncNotificationPermissionToBackend();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBody: false,
      body: IndexedStack(index: _currentTabIndex, children: _navigationTabScreens),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }
}
