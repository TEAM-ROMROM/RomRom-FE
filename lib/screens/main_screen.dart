import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/chat_tab_screen.dart';
import 'package:romrom_fe/screens/home_tab_screen.dart';
import 'package:romrom_fe/screens/my_page_tab_screen.dart';
import 'package:romrom_fe/screens/register_tab_screen.dart';
import 'package:romrom_fe/screens/request_management_tap_screen.dart';
import 'package:romrom_fe/widgets/custom_bottom_navigation_bar.dart';

/// 홈 화면
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 선택된 탭 인덱스 관리

  // 각 탭에 해당하는 페이지 위젯 리스트
  final List<Widget> _pages = [
    const HomeTabScreen(),
    const RequestManagementTabScreen(),
    const RegisterTabScreen(),
    const ChatTabScreen(),
    const MyPageTabScreen(),
  ];

  // 각 탭에 해당하는 제목 리스트
  final List<String> _titles = ['홈', '요청 관리', '등록', '채팅', '마이페이지'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex], style: CustomTextStyles.h3),
      ),
      // 현재 선택된 인덱스에 맞는 페이지 표시
      body: _pages[_selectedIndex],
      // 바텀 네비게이션 바
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}