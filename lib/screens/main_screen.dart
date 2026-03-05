import 'package:flutter/material.dart';
import 'package:romrom_fe/screens/chat_tab_screen.dart';
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

class _MainScreenState extends State<MainScreen> {
  int _currentTabIndex = 0; // 선택된 탭 인덱스 관리

  @override
  void initState() {
    super.initState();
    HeartbeatManager.instance.start();
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
  void dispose() {
    super.dispose();
  }

  // 각 탭에 해당하는 페이지 위젯 리스트
  final List<Widget> _navigationTabScreens = [
    HomeTabScreen(key: HomeTabScreen.globalKey),
    const RequestManagementTabScreen(),
    const RegisterTabScreen(),
    const ChatTabScreen(),
    const MyPageTabScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBody: false,
      body: _navigationTabScreens[_currentTabIndex],
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
