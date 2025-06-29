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

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentTabIndex = 0; // 선택된 탭 인덱스 관리

  // 각 탭에 해당하는 페이지 위젯 리스트
  final List<Widget> _navigationTabScreens = [
    const HomeTabScreen(),
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
      appBar: _currentTabIndex != 0
          ? AppBar(
              backgroundColor: Colors.transparent,
              title: Text(currentTab.title, style: CustomTextStyles.h3),
            )
          : null, // 홈 탭에서는 AppBar 숨김
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
