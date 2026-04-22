import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/enums/trade_review_rating.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class RatingOptionButton extends StatefulWidget {
  final TradeReviewRating rating;
  final bool isSelected;
  final VoidCallback onTap;

  const RatingOptionButton({super.key, required this.rating, required this.isSelected, required this.onTap});

  @override
  State<RatingOptionButton> createState() => _RatingOptionButtonState();
}

class _RatingOptionButtonState extends State<RatingOptionButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _popScale;
  late final Animation<double> _moveY;
  late final Animation<double> _rotation;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 340));

    _popScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: _targetScale).chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: _targetScale, end: 0.96).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 35),
    ]).animate(_controller);

    _moveY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: _targetLift).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: _targetLift, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    _rotation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: _targetRotation).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: _targetRotation, end: -_targetRotation * 0.6).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -_targetRotation * 0.6, end: 0.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant RatingOptionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSelected && widget.isSelected) {
      _controller.forward(from: 0);
    }
  }

  double get _targetScale => switch (widget.rating) {
    TradeReviewRating.bad => 1.08,
    TradeReviewRating.good => 1.12,
    TradeReviewRating.great => 1.16,
  };

  double get _targetLift => switch (widget.rating) {
    TradeReviewRating.bad => -4,
    TradeReviewRating.good => -8,
    TradeReviewRating.great => -10,
  };

  double get _targetRotation => switch (widget.rating) {
    TradeReviewRating.bad => 0.06,
    TradeReviewRating.good => 0.03,
    TradeReviewRating.great => 0.09,
  };

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: 90.w,
                height: 90.w,
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? widget.rating.selectedBackgroundColor
                      : AppColors.reviewRatingUnselectedBackground,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: widget.rating.selectedColor.withValues(alpha: 0.22),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, isSelected ? _moveY.value : 0),
                      child: Transform.rotate(
                        angle: isSelected ? _rotation.value : 0,
                        child: Transform.scale(scale: isSelected ? _popScale.value : 1.0, child: child),
                      ),
                    );
                  },
                  child: ClipOval(
                    child: SvgPicture.asset(
                      isSelected ? widget.rating.selectedImgAsset : widget.rating.unselectedImgAsset,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                style: CustomTextStyles.h3.copyWith(
                  color: isSelected ? widget.rating.selectedColor : AppColors.reviewRatingUnselected,
                ),
                child: Text(widget.rating.label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
