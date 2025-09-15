import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class ContextMenuItem {
  final String id;
  final String title;
  final IconData? icon;
  final Color? textColor;
  final VoidCallback onTap;
  final bool showDividerAfter;

  const ContextMenuItem({
    required this.id,
    required this.title,
    required this.onTap,
    this.icon,
    this.textColor,
    this.showDividerAfter = false,
  });
}

enum ContextMenuPosition { auto, above, below, left, right }

enum ContextMenuAnimation { scale, fade, slideDown, cornerExpand }

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

  const RomRomContextMenu({
    super.key,
    required this.items,
    this.customTrigger,
    this.animation = ContextMenuAnimation.cornerExpand,
    this.position = ContextMenuPosition.auto,
    this.onItemSelected,
    this.menuWidth,
    this.menuPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.menuBorderRadius,
    this.menuBackgroundColor,
    this.itemHeight = 46,
    this.enableHapticFeedback = true,
  });

  @override
  State<RomRomContextMenu> createState() => _RomRomContextMenuState();
}

class _RomRomContextMenuState extends State<RomRomContextMenu>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final GlobalKey _triggerKey = GlobalKey();
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

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

    final RenderBox? renderBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
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
        menuWidth: widget.menuWidth ?? 146.w,
        menuPadding: widget.menuPadding,
        menuBorderRadius: widget.menuBorderRadius ?? BorderRadius.circular(4.r),
        menuBackgroundColor:
            widget.menuBackgroundColor ?? AppColors.secondaryBlack1,
        itemHeight: widget.itemHeight.h,
        onItemSelected: (id) {
          _closeMenu();
          widget.onItemSelected?.call(id);
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
      setState(() {
        _isMenuOpen = false;
      });
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _triggerKey,
      onTap: _showMenu,
      child: widget.customTrigger ??
          Icon(
            AppIcons.dotsVertical,
            size: 30.sp,
            color: AppColors.textColorWhite,
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
  final Function(String) onItemSelected;
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
        return Transform.scale(
          scale: animation.value,
          alignment: Alignment.topCenter,
          child: child,
        );
      case ContextMenuAnimation.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      case ContextMenuAnimation.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.2),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      case ContextMenuAnimation.cornerExpand:
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.85 + (animation.value * 0.15),
              alignment: Alignment.topCenter,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
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
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.opacity20Black,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: menuBorderRadius,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _buildMenuItems(),
                        ),
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
        InkWell(
          onTap: () {
            if (enableHapticFeedback) {
              HapticFeedback.selectionClick();
            }
            item.onTap();
            onItemSelected(item.id);
          },
          child: Container(
            height: itemHeight,
            padding: menuPadding,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(
                    item.icon,
                    size: 18.sp,
                    color: item.textColor ?? AppColors.textColorWhite,
                  ),
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

      if (item.showDividerAfter && i < items.length - 1) {
        widgets.add(
          Divider(
            color: AppColors.opacity10White,
            thickness: 1.h,
            height: 1.h,
            indent: menuPadding.left,
            endIndent: menuPadding.right,
          ),
        );
      }
    }

    return widgets;
  }
}
