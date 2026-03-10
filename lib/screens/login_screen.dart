// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:romrom_fe/enums/login_platforms.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/auth_button_group.dart';
import 'package:romrom_fe/widgets/login_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    const List<LoginPlatforms> loginPlatforms = LoginPlatforms.values; // 모든 플랫폼을 가져옴

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset('assets/images/romrom-logo.svg', width: 108.w, height: 112.h),
                SizedBox(height: 45.h), // 간격 추가
                // 서비스 간단 소개 텍스트
                Text(
                  '손쉬운 물건 교환',
                  style: CustomTextStyles.p1.copyWith(
                    color: AppColors.textColorWhite.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 17.0.h), // 간격 추가
                // "romrom" 이미지
                SvgPicture.asset('assets/images/login-romrom-text.svg', width: 124.w, height: 17.h),
                SizedBox(height: 174.0.h), // 간격 추가
                // 로그인 버튼 그룹
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0.w),
                  child: AuthButtonGroup(
                    buttons: loginPlatforms.map((platform) => LoginButton(platform: platform)).toList(),
                  ),
                ),
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
