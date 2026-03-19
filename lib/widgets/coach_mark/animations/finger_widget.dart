import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/finger_direction.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 손가락 아이콘이 지정 방향으로 반복 이동하는 위젯
class FingerWidget extends StatefulWidget {
  final FingerDirection direction;
  final double size;
  final double travelDistance;

  const FingerWidget({super.key, this.direction = FingerDirection.upDown, this.size = 56, this.travelDistance = 24});

  @override
  State<FingerWidget> createState() => _FingerWidgetState();
}

class _FingerWidgetState extends State<FingerWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        double dx = 0, dy = 0;
        final t = (_anim.value - 0.5) * widget.travelDistance * 2;
        switch (widget.direction) {
          case FingerDirection.upDown:
            dy = t;
            break;
          case FingerDirection.up:
            dy = -_anim.value * widget.travelDistance;
            break;
          case FingerDirection.down:
            dy = _anim.value * widget.travelDistance;
            break;
          case FingerDirection.leftRight:
            dx = t;
            break;
        }
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      child: Icon(
        Icons.touch_app_rounded,
        size: widget.size,
        color: AppColors.textColorWhite,
        shadows: const [Shadow(color: AppColors.opacity20Black, blurRadius: 8)],
      ),
    );
  }
}
