import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // SVG 이미지를 사용하기 위해 추가
import 'package:romrom_fe/enums/login_platforms.dart';
import 'package:romrom_fe/widgets/auth_button_group.dart';
import 'package:romrom_fe/widgets/login_button.dart';

/// 로그인 화면
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const List<LoginPlatforms> platforms = LoginPlatforms.values; // 모든 플랫폼을 가져옴

    return Scaffold(
      backgroundColor: Colors.black, // 배경색을 검정색으로 설정 (이미지와 유사하게)
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 (SVG)
            SvgPicture.asset(
              'assets/icons/temp-logo.svg',
              width: 100, // 로고 크기 조정 (필요에 따라 수정)
              height: 100,
            ),
            const SizedBox(height: 50), // 간격 추가
            // 서비스 간단 소개 텍스트
            const Text(
              '손쉬운 물건 교환',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10), // 간격 추가
            // "romrom" 이미지
            SvgPicture.asset(
              'assets/images/login-romrom-text.svg',
              width: 30,
              height: 20,
            ),
            const SizedBox(height: 120), // 간격 추가
            // 로그인 버튼 그룹
            AuthButtonGroup(
              buttons: platforms
                  .map((platform) => LoginButton(platform: platform))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}