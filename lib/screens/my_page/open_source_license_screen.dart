import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/font_family.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 오픈소스 라이선스 화면: Flutter 기본 라이선스 목록 + 앱 어두운 배경·노란 강조색
class OpenSourceLicenseScreen extends StatelessWidget {
  final String appVersion;

  const OpenSourceLicenseScreen({super.key, required this.appVersion});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: FontFamily.pretendard.fontName,
        scaffoldBackgroundColor: AppColors.primaryBlack,
        cardColor: AppColors.primaryBlack,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryYellow,
          surface: AppColors.primaryBlack,
          onSurface: AppColors.textColorWhite,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryBlack,
          foregroundColor: AppColors.textColorWhite,
          surfaceTintColor: AppColors.transparent,
        ),
      ),
      child: LicensePage(applicationName: '롬롬', applicationVersion: appVersion.isEmpty ? null : 'v$appVersion'),
    );
  }
}
