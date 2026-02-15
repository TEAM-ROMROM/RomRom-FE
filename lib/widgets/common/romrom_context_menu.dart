import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/enums/context_menu_enums.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class ContextMenuItem {
  final String id;
  final String title;
  final IconData? contextIcon;
  final IconData? icon;
  final String? svgAssetPath;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback onTap;
  final bool showDividerAfter;

  const ContextMenuItem({
    required this.id,
    required this.title,
    required this.onTap,
    this.contextIcon = AppIcons.dotsVerticalDefault,
    this.icon,
    this.svgAssetPath,
    this.iconColor = AppColors.opacity60White,
    this.textColor,
    this.showDividerAfter = false,
  });
}

class RomRomContextMenu extends StatefulWidget {
  final List<ContextMenuItem> items;
  final Widget? customTrigger;
  final ContextMenuAnimation animation;
  final ContextMenuPosition position;
  final Function(String)? onItemSelected;
  final double? menuWidth;
  final EdgeInsets menuPadding;
  final BorderRadius? menuBorderRadius;
  final Color? menuBackgroundColor;
  final double itemHeight;
  final bool enableHapticFeedback;
  final double triggerRotationDegreesOnOpen;

  /// 0이면 회전 없음, 45면 45도 회전

  const RomRomContextMenu({
    super.key,
    required this.items,
    this.customTrigger,
    this.animation = ContextMenuAnimation.cornerExpand,
    this.position = ContextMenuPosition.auto,
    this.onItemSelected,
    this.menuWidth,
    this.menuPadding = const EdgeInsets.only(left: 16, top: 16, bottom: 16),
    this.menuBorderRadius,
    this.menuBackgroundColor,
    this.itemHeight = 52,
    this.enableHapticFeedback = true,
    this.triggerRotationDegreesOnOpen = 0,
  });

  @override
  State<RomRomContextMenu> createState() => _RomRomContextMenuState();
}

class _RomRomContextMenuState extends State<RomRomContextMenu> with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final GlobalKey _triggerKey = GlobalKey();
  bool _isMenuOpen = false;
  bool _isItemHandling = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 250), vsync: this);

    final curve = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _showMenu() {
    if (_isMenuOpen) {
      _closeMenu();
      return;
    }

    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    final RenderBox? renderBox = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final triggerSize = renderBox.size;
    final triggerPosition = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => _MenuOverlay(
        items: widget.items,
        animation: _animation,
        animationType: widget.animation,
        position: widget.position,
        triggerPosition: triggerPosition,
        triggerSize: triggerSize,
        menuWidth: widget.menuWidth ?? 200.w,
        menuPadding: widget.menuPadding,
        menuBorderRadius: widget.menuBorderRadius ?? BorderRadius.circular(10.r),
        menuBackgroundColor: widget.menuBackgroundColor ?? AppColors.primaryBlack,
        itemHeight: widget.itemHeight.h,
        onItemSelected: (ContextMenuItem item) {
          if (_isItemHandling) return;
          _isItemHandling = true;

          _closeMenu();
          item.onTap();
          widget.onItemSelected?.call(item.id); // 외부 콜백도 1번
        },

        onDismiss: _closeMenu,
        enableHapticFeedback: widget.enableHapticFeedback,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
    setState(() {
      _isMenuOpen = true;
    });
  }

  void _closeMenu() {
    if (!_isMenuOpen) return;

    _animationController.reverse().then((_) {
      _removeOverlay();
      if (mounted) {
        setState(() => _isMenuOpen = false);
      }
      _isItemHandling = false;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final triggerChild =
        widget.customTrigger ?? Icon(widget.items.first.contextIcon, size: 30.sp, color: AppColors.textColorWhite);

    return GestureDetector(
      key: _triggerKey,
      onTap: _showMenu,
      child: widget.triggerRotationDegreesOnOpen == 0
          ? triggerChild
          : AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final radians = (widget.triggerRotationDegreesOnOpen * _animationController.value) * (math.pi / 180.0);
                return Transform.rotate(angle: radians, child: child);
              },
              child: triggerChild,
            ),
    );
  }
}

class _MenuOverlay extends StatelessWidget {
  final List<ContextMenuItem> items;
  final Animation<double> animation;
  final ContextMenuAnimation animationType;
  final ContextMenuPosition position;
  final Offset triggerPosition;
  final Size triggerSize;
  final double menuWidth;
  final EdgeInsets menuPadding;
  final BorderRadius menuBorderRadius;
  final Color menuBackgroundColor;
  final double itemHeight;
  final void Function(ContextMenuItem) onItemSelected;
  final VoidCallback onDismiss;
  final bool enableHapticFeedback;

  const _MenuOverlay({
    required this.items,
    required this.animation,
    required this.animationType,
    required this.position,
    required this.triggerPosition,
    required this.triggerSize,
    required this.menuWidth,
    required this.menuPadding,
    required this.menuBorderRadius,
    required this.menuBackgroundColor,
    required this.itemHeight,
    required this.onItemSelected,
    required this.onDismiss,
    required this.enableHapticFeedback,
  });

  Offset _calculateMenuPosition(Size screenSize) {
    double menuHeight = _calculateMenuHeight();
    double left = triggerPosition.dx;
    double top = triggerPosition.dy + triggerSize.height + 12.h;

    switch (position) {
      case ContextMenuPosition.above:
        top = triggerPosition.dy - menuHeight - 12.h;
        break;
      case ContextMenuPosition.below:
        top = triggerPosition.dy + triggerSize.height + 12.h;
        break;
      case ContextMenuPosition.left:
        left = triggerPosition.dx - menuWidth - 12.w;
        top = triggerPosition.dy;
        break;
      case ContextMenuPosition.right:
        left = triggerPosition.dx + triggerSize.width + 12.w;
        top = triggerPosition.dy;
        break;
      case ContextMenuPosition.auto:
        if (left + menuWidth > screenSize.width - 24.w) {
          left = triggerPosition.dx + triggerSize.width - menuWidth;
        }
        if (top + menuHeight > screenSize.height - 100.h) {
          top = triggerPosition.dy - menuHeight - 12.h;
        }
        break;
    }

    left = left.clamp(12.w, screenSize.width - menuWidth - 12.w);
    top = top.clamp(50.h, screenSize.height - menuHeight - 50.h);

    return Offset(left, top);
  }

  double _calculateMenuHeight() {
    double height = 0;
    for (int i = 0; i < items.length; i++) {
      height += itemHeight;
      if (items[i].showDividerAfter && i < items.length - 1) {
        height += 1.h;
      }
    }
    return height;
  }

  Widget _buildAnimatedMenu(Widget child, Offset menuPosition) {
    switch (animationType) {
      case ContextMenuAnimation.scale:
        return Transform.scale(scale: animation.value, alignment: Alignment.topCenter, child: child);
      case ContextMenuAnimation.fade:
        return FadeTransition(opacity: animation, child: child);
      case ContextMenuAnimation.slideDown:
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      case ContextMenuAnimation.cornerExpand:
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.85 + (animation.value * 0.15),
              alignment: Alignment.topCenter,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: child,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final menuPosition = _calculateMenuPosition(screenSize);

    return Stack(
      children: [
        // 투명 오버레이 - 메뉴 외부 영역 탭/제스처 감지
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent, // 다른 UI 요소 통과
            onTap: onDismiss,
            onPanStart: (_) => onDismiss(), // 모든 드래그 제스처 감지
            child: Container(color: AppColors.transparent),
          ),
        ),
        // 메뉴
        Positioned(
          left: menuPosition.dx,
          top: menuPosition.dy,
          child: IgnorePointer(
            ignoring: false, // 메뉴 자체는 터치 이벤트 받음
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return _buildAnimatedMenu(
                  Material(
                    color: AppColors.transparent,
                    child: Container(
                      width: menuWidth,
                      decoration: BoxDecoration(
                        color: menuBackgroundColor,
                        borderRadius: menuBorderRadius,
                        border: Border.all(color: AppColors.secondaryBlack1, width: 0.5),
                        boxShadow: const [
                          BoxShadow(color: AppColors.opacity50Black, blurRadius: 20, offset: Offset(0, 5)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: menuBorderRadius,
                        child: Column(mainAxisSize: MainAxisSize.min, children: _buildMenuItems()),
                      ),
                    ),
                  ),
                  menuPosition,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMenuItems() {
    final List<Widget> widgets = [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      widgets.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (enableHapticFeedback) {
              HapticFeedback.selectionClick();
            }
            onItemSelected(item);
          },
          child: Container(
            height: itemHeight,
            padding: menuPadding,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                // SVG 아이콘 우선, 없으면 IconData 사용
                if (item.svgAssetPath != null) ...[
                  SvgPicture.asset(item.svgAssetPath!, width: 20.sp, height: 20.sp),
                  SizedBox(width: 8.w),
                ] else if (item.icon != null) ...[
                  Icon(item.icon, size: 20.sp, color: item.iconColor ?? AppColors.opacity60White),
                  SizedBox(width: 8.w),
                ],
                Text(
                  item.title,
                  style: CustomTextStyles.p2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: item.textColor ?? AppColors.textColorWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // 디바이더: 왼쪽 16px, 오른쪽 26px 패딩
      if (item.showDividerAfter && i < items.length - 1) {
        widgets.add(
          Divider(color: AppColors.secondaryBlack1, thickness: 1.h, height: 1.h, indent: 16.w, endIndent: 26.w),
        );
      }
    }

    return widgets;
  }
}
