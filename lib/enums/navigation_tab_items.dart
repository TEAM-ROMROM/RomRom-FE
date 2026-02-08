// lib/enums/navigation_tab_items.dart
import 'package:flutter/material.dart';
import 'package:romrom_fe/icons/app_icons.dart';

/// 네비게이션 탭 항목 정의
/// `title`: 탭 제목
/// `icon`: 탭 아이콘
enum NavigationTabItems {
  home(title: '홈', iconData: AppIcons.home),
  requestManagement(title: '요청 관리', iconData: AppIcons.requestManagement),
  register(title: '내 물건', iconData: AppIcons.register),
  chat(title: '채팅', iconData: AppIcons.chat),
  myPage(title: '마이페이지', iconData: AppIcons.myPage);

  final String title;
  final IconData iconData;

  const NavigationTabItems({required this.title, required this.iconData});

  static NavigationTabItems fromIndex(int index) {
    return values.firstWhere((tab) => tab.index == index, orElse: () => home);
  }
}
