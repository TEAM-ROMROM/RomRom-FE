import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 공통 글래스 헤더 Delegate
class GlassHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget toggle;
  final String headerTitle;
  final double statusBarHeight; // MediaQuery.of(context).padding.top 전달 필요
  final double toolbarHeight; // 예: 58.h
  final double toggleHeight; // 예: 70.h
  final double expandedExtra; // 큰 제목/여백 등 “펼침 전용” 추가 높이
  final bool enableBlur;

  GlassHeaderDelegate({
    required this.toggle,
    required this.headerTitle,
    required this.statusBarHeight,
    required this.toolbarHeight,
    required this.toggleHeight,
    this.expandedExtra = 32.0,
    this.enableBlur = true,
  }) : assert(statusBarHeight >= 0 && toolbarHeight >= 0 && toggleHeight >= 0);

  // 토글을 포함해서 최소 높이를 정의 → 토글이 항상 보임
  @override
  double get minExtent => statusBarHeight + toolbarHeight + toggleHeight;

  // 펼쳐질 때만 추가로 커지는 영역(큰 제목 등)
  @override
  double get maxExtent => minExtent + expandedExtra;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final extraRange = (maxExtent - minExtent).clamp(0.0, double.infinity);
    final t =
        extraRange == 0 ? 1.0 : (shrinkOffset / extraRange).clamp(0.0, 1.0);

    final sigma = enableBlur ? lerpDouble(0, 30, t)! : 0.0;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1) 블러
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: const SizedBox.expand(),
          ),

          // 2) 틴트 (단색)
          Container(
            decoration: const BoxDecoration(
              color: AppColors.opacity90PrimaryBlack,
            ),
          ),

          // 3) 큰 제목(펼침에서만 보이고 스크롤되면 사라짐)
          Positioned(
            left: 24,
            right: 24,
            top: statusBarHeight + 32,
            child: Opacity(
              opacity: 1.0 - t,
              child: Text(headerTitle, style: CustomTextStyles.h1),
            ),
          ),

          // 4) 작은 제목(툴바 타이틀 역할) — 스크롤될수록 나타남
          Positioned(
            left: 0,
            right: 0,
            top: statusBarHeight,
            height: toolbarHeight,
            child: IgnorePointer(
              ignoring: true,
              child: Center(
                child: Opacity(
                  opacity: t,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 24),
                    child: Text(
                      headerTitle,
                      style: CustomTextStyles.h3
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 5) 토글: 항상 보이는 영역(최소 높이에 포함시켰기 때문에 사라지지 않음)
          Positioned(
            left: 0,
            right: 0,
            top: statusBarHeight + toolbarHeight + lerpDouble(24, 0, t)!,
            height: toggleHeight,
            child: Material(
              color: Colors.transparent,
              child: toggle,
            ),
          ),

          // 6) 하단 라인(살짝)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.15 * t,
              child: const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.opacity20Black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant GlassHeaderDelegate oldDelegate) {
    return toggle != oldDelegate.toggle ||
        headerTitle != oldDelegate.headerTitle ||
        statusBarHeight != oldDelegate.statusBarHeight ||
        toolbarHeight != oldDelegate.toolbarHeight ||
        toggleHeight != oldDelegate.toggleHeight ||
        expandedExtra != oldDelegate.expandedExtra ||
        enableBlur != oldDelegate.enableBlur;
  }
}

/// 공통 토글 위젯 빌더 (좌/우 선택 토글)
/// 화면별로 동일한 스타일의 토글을 재사용할 수 있게 제공
class GlassHeaderToggleBuilder {
  /// 애니메이션 값과 상태만 주면 동일한 UI를 반환
  static Widget buildDefaultToggle({
    required Animation<double> animation,
    required bool isRightSelected,
    required VoidCallback onLeftTap,
    required VoidCallback onRightTap,
    required String leftText,
    required String rightText,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
      child: Container(
        width: 345.w,
        height: 46.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          color: AppColors.secondaryBlack1,
        ),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Stack(
              children: [
                // 선택된 배경 이동
                Positioned(
                  left: 2.w + (animation.value * 171.w),
                  top: 2.h,
                  child: Container(
                    width: 170.w,
                    height: 42.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      color: AppColors.primaryBlack,
                    ),
                  ),
                ),
                // 좌/우 탭 영역
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onLeftTap,
                        child: Container(
                          height: 46.h,
                          color: Colors.transparent,
                          alignment: Alignment.center,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: CustomTextStyles.p2.copyWith(
                              color: !isRightSelected
                                  ? AppColors.textColorWhite
                                  : AppColors.opacity50White,
                            ),
                            child: Text(leftText),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: onRightTap,
                        child: Container(
                          height: 46.h,
                          color: Colors.transparent,
                          alignment: Alignment.center,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: CustomTextStyles.p2.copyWith(
                              color: isRightSelected
                                  ? AppColors.textColorWhite
                                  : AppColors.opacity50White,
                            ),
                            child: Text(rightText),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
