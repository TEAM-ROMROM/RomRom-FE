import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 거래 완료 토글 스위치 위젯
class CompletedToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CompletedToggleSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40.w,
        height: 20.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          color: value ? AppColors.primaryYellow : const Color(0x33FFFFFF), // 활성/비활성 색상
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: value ? 19.w : 2.w,
              top: 1.h,
              child: Container(
                width: 18.w,
                height: 18.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(64), // 25% opacity
                      blurRadius: 2.r,
                      offset: Offset(-1.w, 0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
