// 물품 상세 하단 고정 액션 버튼 (채팅하기·요청하기, Stack 하단 고정, 숨김이면 빈 SizedBox)
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/widgets/common/custom_floating_button.dart';

class ItemDetailBottomActionButton extends StatelessWidget {
  final bool isVisible;
  final bool isEnabled;
  final String buttonText;
  final VoidCallback onPressed;

  const ItemDetailBottomActionButton({
    super.key,
    required this.isVisible,
    required this.isEnabled,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox();

    return Positioned(
      // 하단 여백: Android 28, iOS 49 (홈 인디케이터 영역)
      bottom: Platform.isAndroid ? 28.h : 49.h,
      left: 0,
      right: 0,
      child: CustomFloatingButton(
        isEnabled: isEnabled,
        enabledOnPressed: onPressed,
        buttonText: buttonText,
        buttonWidth: 346,
        buttonHeight: 56,
      ),
    );
  }
}
