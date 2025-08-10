import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 두 가지 옵션 중 하나를 선택하는 토글 위젯
/// 애니메이션 효과가 있는 선택 배경과 텍스트 색상 전환을 지원합니다.
class ToggleSelector extends StatefulWidget {
  /// 왼쪽 옵션 텍스트
  final String leftText;
  
  /// 오른쪽 옵션 텍스트
  final String rightText;
  
  /// 현재 선택된 상태 (false: 왼쪽, true: 오른쪽)
  final bool isRightSelected;
  
  /// 토글 선택 변경 시 호출되는 콜백
  final Function(bool) onToggleChanged;
  
  /// 위젯 하단 패딩 (기본값: 24)
  final double bottomPadding;

  const ToggleSelector({
    super.key,
    required this.leftText,
    required this.rightText,
    required this.isRightSelected,
    required this.onToggleChanged,
    this.bottomPadding = 24.0,
  });

  @override
  State<ToggleSelector> createState() => _ToggleSelectorState();
}

class _ToggleSelectorState extends State<ToggleSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _toggleAnimationController;
  late Animation<double> _toggleAnimation;

  @override
  void initState() {
    super.initState();
    
    // 토글 애니메이션 초기화
    _toggleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _toggleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _toggleAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // 초기 상태 설정
    if (widget.isRightSelected) {
      _toggleAnimationController.value = 1.0;
    } else {
      _toggleAnimationController.value = 0.0;
    }
  }
  
  @override
  void didUpdateWidget(covariant ToggleSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 외부에서 상태가 변경된 경우 애니메이션 컨트롤러 값을 업데이트
    if (oldWidget.isRightSelected != widget.isRightSelected) {
      if (widget.isRightSelected) {
        _toggleAnimationController.forward();
      } else {
        _toggleAnimationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _toggleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, widget.bottomPadding.h),
      child: Container(
        width: 345.w,
        height: 46.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          color: AppColors.secondaryBlack,
        ),
        child: Stack(
          children: [
            // 애니메이션 선택된 배경
            AnimatedBuilder(
              animation: _toggleAnimation,
              builder: (context, child) {
                return Positioned(
                  left: 2.w + (_toggleAnimation.value * 171.w), // 2px + 170px + 1px gap
                  top: 2.h,
                  child: Container(
                    width: 170.w,
                    height: 42.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      color: AppColors.primaryBlack,
                    ),
                  ),
                );
              },
            ),
            // 텍스트 버튼들
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onToggleChanged(false),
                    child: Container(
                      height: 46.h,
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Text(
                        widget.leftText,
                        style: CustomTextStyles.p1.copyWith(
                          color: !widget.isRightSelected
                              ? AppColors.textColorWhite
                              : AppColors.opacity60White,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onToggleChanged(true),
                    child: Container(
                      height: 46.h,
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Text(
                        widget.rightText,
                        style: CustomTextStyles.p1.copyWith(
                          color: widget.isRightSelected
                              ? AppColors.textColorWhite
                              : AppColors.opacity60White,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
