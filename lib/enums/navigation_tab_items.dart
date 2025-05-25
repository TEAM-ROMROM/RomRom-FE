// lib/enums/navigation_tab_items.dart
import 'package:flutter/material.dart';
import 'package:romrom_fe/icons/app_icons.dart';

/// 네비게이션 탭 항목 정의
/// `title`: 탭 제목
/// `icon`: 탭 아이콘
enum NavigationTabItems {
  home(title: '홈', icon: AppIcons.home),
  requestManagement(title: '요청 관리', icon: AppIcons.requestManagement),
  register(title: '등록', icon: AppIcons.register),
  chat(title: '채팅', icon: AppIcons.chat),
  myPage(title: '마이페이지', icon: AppIcons.myPage);

  final String title;
  final IconData icon;

  const NavigationTabItems({
    required this.title,
    required this.icon
  });

  static NavigationTabItems fromIndex(int index) {
    return values.firstWhere(
          (tab) => tab.index == index,
      orElse: () => home,
    );
  }
}