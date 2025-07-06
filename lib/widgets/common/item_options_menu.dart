import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class ItemOptionsMenu extends StatelessWidget {
  final VoidCallback? onEditPressed;
  final VoidCallback? onDeletePressed;

  const ItemOptionsMenu({
    super.key,
    this.onEditPressed,
    this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 146.w,
      height: 93.h,
      decoration: BoxDecoration(
        color: const Color(0xFF34353D),
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 수정 버튼
          InkWell(
            onTap: onEditPressed,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
              child: Text(
                '수정',
                style: TextStyle(
                  color: AppColors.textColorWhite,
                  fontFamily: 'Pretendard',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.0, // 100% line-height
                ),
              ),
            ),
          ),
          // 구분선
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Container(
              width: 122.w,
              height: 1.h,
              color: AppColors.textColorWhite
                  .withValues(alpha: 26), // FFFFFF1A -> 10%
            ),
          ),
          // 삭제 버튼
          InkWell(
            onTap: onDeletePressed,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
              child: Text(
                '삭제',
                style: TextStyle(
                  color: const Color(0xFFFF5656), // #FF5656
                  fontFamily: 'Pretendard',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.0, // 100% line-height
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 현재 표시된 메뉴를 추적하는 전역 변수
OverlayEntry? _currentMenuEntry;

// 아이템 옵션 메뉴를 표시하는 함수
void showItemOptionsMenu({
  required BuildContext context,
  required GlobalKey iconKey,
  VoidCallback? onEditPressed,
  VoidCallback? onDeletePressed,
}) {
  // 이미 열린 메뉴가 있으면 닫기
  if (_currentMenuEntry != null) {
    _currentMenuEntry!.remove();
    _currentMenuEntry = null;
  }

  // 아이콘의 위치를 가져옴
  final RenderBox? renderBox =
      iconKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return;

  final position = renderBox.localToGlobal(Offset.zero);
  final size = renderBox.size;

  // Overlay에 메뉴를 표시
  final overlay = Overlay.of(context);
  OverlayEntry? entry;

  _currentMenuEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: position.dy + size.height + 12.h, // 아이콘 하단에서 12px 아래
      left: position.dx + size.width - 146.w, // 오른쪽 정렬
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => entry?.remove(),
          child: Stack(
            children: [
              GestureDetector(
                onTap: () {
                  _currentMenuEntry?.remove();
                  _currentMenuEntry = null;
                },
                child: ItemOptionsMenu(
                  onEditPressed: () {
                    _currentMenuEntry?.remove();
                    _currentMenuEntry = null;
                    if (onEditPressed != null) onEditPressed();
                  },
                  onDeletePressed: () {
                    _currentMenuEntry?.remove();
                    _currentMenuEntry = null;
                    if (onDeletePressed != null) onDeletePressed();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(_currentMenuEntry!);
}
