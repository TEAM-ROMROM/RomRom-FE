import 'dart:io';

import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/navigation_tab_items.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({super.key, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    double bottomPadding = Platform.isIOS ? 58 + MediaQuery.of(context).padding.bottom : 70;
    return Container(
      width: MediaQuery.of(context).size.width,
      // 기본 높이 + 시스템 네비게이션 영역 패딩
      height: bottomPadding,
      decoration: const BoxDecoration(
        color: AppColors.primaryBlack,
        border: Border(top: BorderSide(color: AppColors.opacity10Black, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: NavigationTabItems.values
            .map((tab) => _buildNavItem(context, tab.index, tab.iconData, tab.title))
            .toList(),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final bool isSelected = selectedIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 5,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              // 아이콘 (선택됨: 흰색, 선택 안됨: 회색)
              Icon(
                icon,
                color: isSelected ? AppColors.textColorWhite : AppColors.bottomNavigationDisableIcon,
                size: 24,
              ),
              const SizedBox(height: 8), // 아이콘과 텍스트 사이 간격
              // 텍스트 (선택됨: 흰색, 선택 안됨: 회색)
              Text(
                label,
                style: CustomTextStyles.p2.copyWith(
                  color: isSelected ? AppColors.textColorWhite : AppColors.bottomNavigationDisableIcon,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
