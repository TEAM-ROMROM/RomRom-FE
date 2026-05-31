import 'dart:io';

import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/navigation_tab_items.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({super.key, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // iOS: 홈 인디케이터 영역 반영, Android: 고정값 (기존 동작 유지)
    final double bottomPadding = Platform.isIOS ? MediaQuery.of(context).padding.bottom : 0;
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: const BoxDecoration(
        color: AppColors.primaryBlack,
        border: Border(top: BorderSide(color: AppColors.opacity10Black, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: NavigationTabItems.values
                .map((tab) => _buildNavItem(context, tab.index, tab.iconData, tab.title))
                .toList(),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final bool isSelected = selectedIndex == index;

    return AppPressable(
      onTap: () => onTap(index),
      scaleDown: AppPressable.scaleIcon,
      enableRipple: false,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 5,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
