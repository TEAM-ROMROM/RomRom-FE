import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';

enum LoginPlatforms {
  kakao(
    iconPath: 'assets/icons/kakao-icon.svg',
    displayText: '카카오로 시작하기',
    backgroundColor: AppColors.kakao,
    platformName: 'KAKAO',
  ),
  google(
    iconPath: 'assets/icons/google-icon.svg',
    displayText: '구글로 시작하기',
    backgroundColor: AppColors.google,
    platformName: 'GOOGLE',
  );

  final String iconPath;
  final String displayText;
  final Color backgroundColor;
  final String platformName;

  const LoginPlatforms({
    required this.iconPath,
    required this.displayText,
    required this.backgroundColor,
    required this.platformName,
  });
}