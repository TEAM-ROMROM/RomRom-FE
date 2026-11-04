import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 동네 인증 지도 하단 '위치 다시 확인' 밑줄 글자 버튼 (저장 중 > 비활성)
class LocationRecheckTextButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onPressed;

  const LocationRecheckTextButton({super.key, required this.isEnabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isEnabled ? onPressed : null,
      child: Text(
        '위치 다시 확인',
        style: CustomTextStyles.p2.copyWith(
          color: AppColors.opacity60White,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.opacity60White,
        ),
      ),
    );
  }
}
