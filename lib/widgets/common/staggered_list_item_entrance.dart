import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/widgets/common/app_fade_slide_in.dart';

/// 지연 생성 목록(SliverList.builder 등) 항목 등장: 앞쪽 항목만 순차 등장 애니메이션 + 유지, 뒤쪽 항목은 애니메이션 없음
/// 유지(keep-alive) > 스크롤로 화면 밖에 나갔다 돌아와도 애니메이션 재생 안 함
class StaggeredListItemEntrance extends StatefulWidget {
  const StaggeredListItemEntrance({super.key, required this.index, required this.child});

  // 등장 애니메이션 항목 수 (지연 상한 안 항목: 0~8번째, 그 뒤는 스크롤해야 보이는 위치)
  static final int animatedItemCount = AppMotion.maximumStaggerDelay.inMilliseconds ~/ AppMotion.staggerDelayMs + 1;

  /// 목록 안 위치 (등장 지연 = index × 간격)
  final int index;

  final Widget child;

  @override
  State<StaggeredListItemEntrance> createState() => _StaggeredListItemEntranceState();
}

class _StaggeredListItemEntranceState extends State<StaggeredListItemEntrance> with AutomaticKeepAliveClientMixin {
  bool get _isAnimated => widget.index < StaggeredListItemEntrance.animatedItemCount;

  @override
  bool get wantKeepAlive => _isAnimated;

  @override
  void didUpdateWidget(covariant StaggeredListItemEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) updateKeepAlive();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_isAnimated) return widget.child;
    return AppFadeSlideIn(
      delay: Duration(milliseconds: widget.index * AppMotion.staggerDelayMs),
      child: widget.child,
    );
  }
}
