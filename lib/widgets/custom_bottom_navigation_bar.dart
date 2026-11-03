import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/navigation_tab_items.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/providers/chat_rooms_provider.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';

// 채팅 탭 안 읽음 점 크기·아이콘 기준 위치 (px, 탭바 고정 크기와 맞춤)
const double _unreadDotSize = 6;
const double _unreadDotOffset = -2;

/// 하단 탭바: 탭 5개 (선택 색 구분), 채팅 탭 안 읽음 점 (chatRoomsProvider 구독)
class CustomBottomNavigationBar extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({super.key, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasUnreadChat = ref.watch(
      chatRoomsProvider.select((roomsAsync) => roomsAsync.valueOrNull?.hasUnreadMessages ?? false),
    );
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
                .map(
                  (tab) => _buildNavItem(
                    context,
                    tab.index,
                    tab.iconData,
                    tab.title,
                    hasUnreadDot: tab == NavigationTabItems.chat && hasUnreadChat,
                  ),
                )
                .toList(),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label, {required bool hasUnreadDot}) {
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
              // 아이콘 (선택됨: 흰색, 선택 안됨: 회색) + 안 읽음 점 (오른쪽 위)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? AppColors.textColorWhite : AppColors.bottomNavigationDisableIcon,
                    size: 24,
                  ),
                  if (hasUnreadDot)
                    Positioned(
                      top: _unreadDotOffset,
                      right: _unreadDotOffset,
                      child: Container(
                        width: _unreadDotSize,
                        height: _unreadDotSize,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.chatUnreadBadge),
                      ),
                    ),
                ],
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
