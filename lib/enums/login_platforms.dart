import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';

enum LoginPlatforms {
  kakao(
    iconPath: 'assets/images/kakao-logo.svg',
    displayText: '카카오로 시작하기',
    backgroundColor: AppColors.kakao,
    platformName: 'KAKAO',
    textColor: AppColors.textColorBlack,
  ),
  apple(
    iconPath: 'assets/images/apple-logo.svg',
    displayText: 'Apple로 시작하기',
    backgroundColor: AppColors.apple,
    platformName: 'APPLE',
    textColor: AppColors.textColorBlack,
  ),
  google(
    iconPath: 'assets/images/google-logo.svg',
    displayText: '구글로 시작하기',
    backgroundColor: AppColors.google,
    platformName: 'GOOGLE',
    textColor: AppColors.textColorBlack,
  );

  final String iconPath;
  final String displayText;
  final Color backgroundColor;
  final String platformName;
  final Color textColor;

  const LoginPlatforms({
    required this.iconPath,
    required this.displayText,
    required this.backgroundColor,
    required this.platformName,
    required this.textColor,
  });
}
