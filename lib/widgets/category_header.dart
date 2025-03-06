import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 카테고리 선택 안내 헤더 문구 빌드
class CategoryHeader extends StatelessWidget {
  final double betweenGap;
  final String headLine;
  final String subHeadLine;

  const CategoryHeader({
    super.key,
    this.betweenGap = 12.0,
    required this.headLine,
    required this.subHeadLine,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(headLine, style: Theme.of(context).textTheme.headlineLarge),
        SizedBox(height: betweenGap.h),
        Text(subHeadLine, style: Theme.of(context).textTheme.headlineMedium),
      ],
    );
  }
}
