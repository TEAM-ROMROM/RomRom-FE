// 물품 상세 세로 스크롤 + 상단 당김 시 헤더 늘림 효과 (당긴 픽셀 1:1 확대, 손 떼면 300ms 복귀)
import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_motion.dart';

class ItemDetailStretchScrollView extends StatefulWidget {
  // 늘림 비율 기준 높이 (헤더 이미지 높이)
  final double stretchBaseHeight;
  final Widget header;
  final Widget body;

  const ItemDetailStretchScrollView({
    super.key,
    required this.stretchBaseHeight,
    required this.header,
    required this.body,
  });

  @override
  State<ItemDetailStretchScrollView> createState() => _ItemDetailStretchScrollViewState();
}

class _ItemDetailStretchScrollViewState extends State<ItemDetailStretchScrollView> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _stretchScaleNotifier = ValueNotifier<double>(1.0);
  static const Duration _returnAnimationDuration = AppMotion.normal;
  late final AnimationController _returnAnimation;
  double _scaleAtRelease = 1.0;

  @override
  void initState() {
    super.initState();
    _returnAnimation = AnimationController(vsync: this, duration: _returnAnimationDuration);
    _returnAnimation.addListener(_onReturnAnimationTick);
    _scrollController.addListener(_onScroll);
  }

  void _onReturnAnimationTick() {
    final progress = AppMotion.entry.transform(_returnAnimation.value);
    _stretchScaleNotifier.value = _scaleAtRelease + (1.0 - _scaleAtRelease) * progress;
  }

  /// ScrollController 리스너: 당긴 픽셀 양 > 헤더 확대 1:1, pixels >= 0 진입 시 1.0 복귀 애니메이션
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pixels = _scrollController.position.pixels;

    if (pixels >= 0) {
      // 손 뗀 직후: scale > 1.0 이고 애니메이션 진행 중이 아닐 때만 시작
      if (_stretchScaleNotifier.value > 1.0 && !_returnAnimation.isAnimating) {
        _scaleAtRelease = _stretchScaleNotifier.value;
        _returnAnimation.forward(from: 0.0);
      }
      return;
    }

    // 당기는 중: 애니메이션이 돌고 있으면 멈추고 즉시 반영
    if (_returnAnimation.isAnimating) _returnAnimation.stop();

    final overscroll = -pixels;
    final baseHeight = widget.stretchBaseHeight;
    if (baseHeight <= 0) return;
    _stretchScaleNotifier.value = 1.0 + overscroll / baseHeight;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _returnAnimation.removeListener(_onReturnAnimationTick);
    _returnAnimation.dispose();
    _stretchScaleNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          ValueListenableBuilder<double>(
            valueListenable: _stretchScaleNotifier,
            builder: (_, scale, child) {
              return Transform.scale(scale: scale, alignment: Alignment.bottomCenter, child: child);
            },
            child: widget.header,
          ),
          widget.body,
        ],
      ),
    );
  }
}
