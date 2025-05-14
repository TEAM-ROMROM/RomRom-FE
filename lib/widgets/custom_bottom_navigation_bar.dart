import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 100.h,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
            color: Color(0x1A000000),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
              context,
              0,
              AppIcons.home,
              '홈'
          ),
          _buildNavItem(
              context,
              1,
              AppIcons.requestManagement,
              '요청 관리'
          ),
          _buildNavItem(
              context,
              2,
              AppIcons.register,
              '등록'
          ),
          _buildNavItem(
              context,
              3,
              AppIcons.chat,
              '채팅'
          ),
          _buildNavItem(
              context,
              4,
              AppIcons.myPage,
              '마이페이지'
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final bool isSelected = selectedIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아이콘 (선택됨: 흰색, 선택 안됨: 회색)
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.bottomNavigationDisableIcon,
              size: 24.sp,
            ),
            SizedBox(height: 9.h), // 아이콘과 텍스트 사이 간격
            // 텍스트 (선택됨: 흰색, 선택 안됨: 회색)
            Text(
              label,
              style: CustomTextStyles.p2.copyWith(
                color: isSelected ? Colors.white : AppColors.bottomNavigationDisableIcon,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}