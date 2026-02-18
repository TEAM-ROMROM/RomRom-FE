import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 공통 앱바 위젯
/// 뒤로가기 버튼과 중앙 정렬된 제목을 기본 제공
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// 앱바에 표시될 제목
  final String title;
  final TextStyle? titleTextStyle;

  /// 뒤로가기 버튼 클릭 시 실행될 콜백
  /// 제공되지 않을 경우 기본적으로 Navigator.pop()이 실행됨
  final VoidCallback? onBackPressed;

  /// 앱바 오른쪽에 표시될 추가 액션 위젯 목록
  final List<Widget>? actions;

  /// 제목 위젯
  final Widget titleWidgets;

  /// 앱바 하단부분에 표시될 위젯 목록
  final PreferredSize bottomWidgets;

  /// 앱바 하단 border 여부
  /// 기본값은 true로 설정되어 있으며, false로 설정하면 하단 border가 표시되지 않음
  final bool showBottomBorder;

  /// 타이틀 클릭 시 실행될 콜백
  /// 제공되지 않을 경우 타이틀은 클릭 불가
  final VoidCallback? onTitleTap;

  const CommonAppBar({
    super.key,
    required this.title,
    this.titleTextStyle,
    this.onBackPressed,
    this.actions,
    this.titleWidgets = const SizedBox.shrink(),
    this.bottomWidgets = const PreferredSize(preferredSize: Size.fromHeight(0), child: SizedBox.shrink()),
    this.showBottomBorder = false,
    this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent, // 투명 배경으로 설정
      elevation: 0, // 그림자 효과 제거
      centerTitle: true, // 제목을 중앙에 배치
      toolbarHeight: 64.h, // 앱바 높이 설정
      scrolledUnderElevation: 0, // 스크롤 할 때 그림자 효과 제거
      leadingWidth: 72.w, // 뒤로가기 버튼 영역 너비 설정
      leading: Material(
        color: Colors.transparent,
        child: ClipOval(
          child: InkResponse(
            customBorder: const CircleBorder(),
            onTap: onBackPressed ?? () => Navigator.of(context).pop(),
            containedInkWell: true,
            radius: 18.w,
            highlightColor: AppColors.buttonHighlightColorGray,
            splashColor: AppColors.buttonHighlightColorGray.withValues(alpha: 0.3),
            child: SizedBox.square(
              dimension: 32.w,
              child: Icon(AppIcons.navigateBefore, size: 24.h, color: AppColors.textColorWhite),
            ),
          ),
        ),
      ),
      bottom: bottomWidgets,
      title: onTitleTap != null
          ? GestureDetector(onTap: onTitleTap, child: titleWidgets)
          : Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(title, style: titleTextStyle ?? CustomTextStyles.h2),
            ),

      actions: actions, // 추가 액션 버튼들
    );
  }

  /// 앱바의 기본 크기 (높이는 64.h로 고정)
  @override
  Size get preferredSize => Size.fromHeight(64.h);
}
