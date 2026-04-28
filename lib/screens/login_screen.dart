// ignore_for_file: prefer_const_constructors
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:romrom_fe/enums/login_platforms.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/auth_button_group.dart';
import 'package:romrom_fe/widgets/login_button.dart';

/// 로그인 화면
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = packageInfo.version);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final List<LoginPlatforms> loginPlatforms = [
      LoginPlatforms.kakao,
      if (Platform.isIOS) LoginPlatforms.apple,
      LoginPlatforms.google,
    ];

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 상단 여백 (화면 높이의 약 15%)
                const Spacer(flex: 2),
                // 로고
                SvgPicture.asset('assets/images/romrom-logo.svg', width: 108.w, height: 108.w),
                SizedBox(height: 45.h),
                // 서비스 간단 소개 텍스트
                Text(
                  '손쉬운 물건 교환',
                  style: CustomTextStyles.p1.copyWith(
                    color: AppColors.textColorWhite.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 17.h),
                // "romrom" 이미지
                SvgPicture.asset('assets/images/login-romrom-text.svg', width: 124.w, height: 17.h),
                // 중간 여백 (화면 높이의 약 25%)
                const Spacer(flex: 3),
                // 로그인 버튼 그룹
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: AuthButtonGroup(
                    buttons: loginPlatforms.map((platform) => LoginButton(platform: platform)).toList(),
                  ),
                ),
                SizedBox(height: 48.h),
              ],
            ),
          ),
          // 우하단 버전 정보
          if (_appVersion.isNotEmpty)
            Positioned(
              right: 20,
              bottom: 40,
              child: Text(
                'v$_appVersion',
                style: CustomTextStyles.p4.copyWith(color: AppColors.textColorWhite.withValues(alpha: 0.4)),
              ),
            ),
        ],
      ),
    );
  }
}
