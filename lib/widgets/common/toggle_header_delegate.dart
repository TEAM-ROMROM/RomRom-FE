import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 토글 위젯을 고정하기 위한 SliverPersistentHeaderDelegate
class ToggleHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  ToggleHeaderDelegate({
    required this.child, 
    this.height = 70,
  });

  @override
  double get minExtent => height.h;

  @override
  double get maxExtent => height.h;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.primaryBlack,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
