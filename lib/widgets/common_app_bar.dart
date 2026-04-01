import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';

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

  /// 앱바 높이 (기본 64, 두 줄 타이틀이 필요한 경우 외부에서 지정)
  final double appBarHeight;

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
    this.appBarHeight = 64,
  });

  @override
  Widget build(BuildContext context) {
    final titleWidget = onTitleTap != null
        ? GestureDetector(onTap: onTitleTap, child: titleWidgets)
        : Text(title, style: titleTextStyle ?? CustomTextStyles.h2);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: appBarHeight,
      scrolledUnderElevation: 0,
      leadingWidth: 72.w,
      leading: AppPressable(
        onTap: onBackPressed ?? () => Navigator.of(context).pop(),
        scaleDown: AppPressable.scaleIcon,
        enableRipple: false,
        child: SizedBox.square(
          dimension: 32.w,
          child: const Icon(AppIcons.navigateBefore, size: 24, color: AppColors.textColorWhite),
        ),
      ),
      bottom: bottomWidgets,
      title: titleWidget,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(appBarHeight);
}
