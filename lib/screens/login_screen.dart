// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/enums/login_platforms.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/widgets/auth_button_group.dart';
import 'package:romrom_fe/widgets/login_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 로그인 화면
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const List<LoginPlatforms> loginPlatforms = LoginPlatforms.values; // 모든 플랫폼을 가져옴

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 (SVG) //FIXME: 아이콘 전환 필요
            SvgPicture.asset(
              'assets/icons/temp-logo.svg',
              width: 100,
              height: 100,
            ),
            SizedBox(height: 50), // 간격 추가
            // 서비스 간단 소개 텍스트
            const Text(
              '손쉬운 물건 교환',
              style: TextStyle(
                color: AppColors.loginDescriptionText,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 13.0.h), // 간격 추가
            // "romrom" 이미지
            SvgPicture.asset(
              'assets/images/login-romrom-text.svg',
              width: 30,
              height: 20,
            ),
            SizedBox(height: 170.0.h), // 간격 추가
            // 로그인 버튼 그룹
            AuthButtonGroup(
              buttons: loginPlatforms
                  .map((platform) => LoginButton(platform: platform))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}