// 물품 상세 하단 액션 버튼 뒤 검정 그라데이션 (Stack 하단 고정, 버튼 없으면 빈 Container)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';

class ItemDetailBottomGradient extends StatelessWidget {
  final bool isVisible;

  const ItemDetailBottomGradient({super.key, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return Container();

    return Positioned(
      bottom: 0,
      child: Container(
        height: 113.h,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.itemDetailBottomBlackGradient, // 검정색 그라데이션
            stops: const [0.0, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}
