import 'package:flutter/material.dart';

import 'package:romrom_fe/services/api/social_auth_sign_in_service.dart';

/// 홈 화면
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void handleBtnTap() {
      logOutWithSocial(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('home'),
      ),
      body: Center(
        child: TextButton(
          onPressed: handleBtnTap,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.pink[300]),
          ),
          child: const Text('logout'),
        ),
      ),
    );
  }
}
