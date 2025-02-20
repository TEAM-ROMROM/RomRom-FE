import 'package:flutter/material.dart';
import 'package:romrom_fe/models/tokens.dart';

import 'package:romrom_fe/screens/home_screen.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/services/app_initializer.dart';
import 'package:romrom_fe/services/kakao_auth_manager.dart';
import 'package:romrom_fe/services/secure_storage_manage.dart';
import 'package:romrom_fe/services/token_manage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initialize(); // 초기화 실행
  Widget initialScreen = await checkTokenStatus(); // 토큰 상태 확인 후 초기 화면 결정

  runApp(MyApp(initialScreen: initialScreen));
}

/// API 기본 URL
const String baseUrl = "https://api.romrom.xyz";

/// 토큰 상태를 확인하여 초기 화면 결정
Future<Widget> checkTokenStatus() async {
  String? refreshToken = await getSecureValueByKey(Tokens.refreshToken.name);

  if (refreshToken == null) return const LoginScreen();
  return await refreshAccessToken() ? const HomeScreen() : const LoginScreen();
}

/// 앱의 루트 위젯
class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RomRom',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: initialScreen,
    );
  }
}
