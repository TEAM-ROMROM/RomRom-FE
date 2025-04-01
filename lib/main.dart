import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/home_screen.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/screens/onboarding/category_selection_screen.dart';
import 'package:romrom_fe/services/api/auth_api.dart';
import 'package:romrom_fe/services/app_initializer.dart';
import 'package:romrom_fe/services/token_manager.dart';

/// API 기본 URL
const String baseUrl = "https://api.romrom.xyz";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initialize(); // 초기화 실행
  final initialScreen = await _determineInitialScreen();

  runApp(MyApp(initialScreen: initialScreen));
}

/// 토큰 상태를 확인하여 초기 화면 결정
Future<Widget> _determineInitialScreen() async {
  final TokenManager tokenManager = TokenManager();
  // refreshToken 불러옴
  final String? refreshToken = await tokenManager.getRefreshToken();

  if (refreshToken == null) return const LoginScreen();
  return await refreshAccessToken() ? const HomeScreen() : const LoginScreen();
}

/// 앱의 루트 위젯
class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      child: Builder(builder: (context) {
        return MaterialApp(
          title: 'RomRom',
          theme: AppTheme.defaultTheme,
          home: initialScreen,
        );
      }),
    );
  }
}
