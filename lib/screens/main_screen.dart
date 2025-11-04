import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/navigation_tab_items.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/chat_tab_screen.dart';
import 'package:romrom_fe/screens/home_tab_screen.dart';
import 'package:romrom_fe/screens/my_page_tab_screen.dart';
import 'package:romrom_fe/screens/register_tab_screen.dart';
import 'package:romrom_fe/screens/request_management_tab_screen.dart';
import 'package:romrom_fe/widgets/custom_bottom_navigation_bar.dart';

/// 메인 화면
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  // MainScreen의 상태에 접근하기 위한 GlobalKey
  static final GlobalKey<State<MainScreen>> globalKey =
      GlobalKey<State<MainScreen>>();

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentTabIndex = 0; // 선택된 탭 인덱스 관리

  /// 외부에서 탭을 전환할 수 있는 메서드
  void switchToTab(int index) {
    if (index >= 0 && index < _navigationTabScreens.length) {
      setState(() {
        _currentTabIndex = index;
      });
    }
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
    // 현재 선택된 탭 정보 가져오기
    final NavigationTabItems currentTab =
        NavigationTabItems.fromIndex(_currentTabIndex);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBody: false,
      appBar: _currentTabIndex == 4
          ? AppBar(
              backgroundColor: Colors.transparent,
              title: Text(currentTab.title, style: CustomTextStyles.h3),
            )
          : null, // 마이페이지 탭에서만 AppBar 표시
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
