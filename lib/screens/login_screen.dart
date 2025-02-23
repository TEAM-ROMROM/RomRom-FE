import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/platforms.dart';
import 'package:romrom_fe/widgets/auth_button_group.dart';
import 'package:romrom_fe/widgets/login_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const List<Platforms> platforms = Platforms.values; // 모든 플랫폼을 가져옴

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로그인 버튼
            const Text('Login'),
            AuthButtonGroup(
              buttons: platforms
                  .map((platform) => LoginButton(platform: platform))
                  .toList(),
            ),
            // 로그아웃 버튼
            const Text("Logout"),
            AuthButtonGroup(
              buttons: platforms
                  .map((platform) => LogoutButton(platform: platform))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
