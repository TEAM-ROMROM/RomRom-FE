import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// AI 배지 위젯
class AiBadgeWidget extends StatelessWidget {
  const AiBadgeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 21.w,
      height: 20.h,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.r),
        color: const Color(0x4DCF7DFF), // rgba(207, 125, 255, 0.30)
      ),
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            colors: [
              Color(0xFF5889F2), // 0%
              Color(0xFF9858F2), // 35%
              Color(0xFFF258F2), // 70%
              Color(0xFFF25893), // 100%
            ],
            stops: [0.0, 0.35, 0.70, 1.0],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds);
        },
        child: Text(
          'AI',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            height: 1.0,
            letterSpacing: -0.5.sp,
            color: Colors.white, // ShaderMask가 적용되기 위한 기본 색상
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}