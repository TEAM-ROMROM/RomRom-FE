import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/main_screen.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';
import 'package:romrom_fe/services/app_initializer.dart';
import 'package:romrom_fe/services/token_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initialize(); // 초기화 실행
  final initialScreen = await _determineInitialScreen();

  // 옵션 1: 하단 오버레이를 포함하도록 수정 (권장)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);

  // 옵션 2: 또는 이 라인을 완전히 제거하여 기본값 사용
  // (SystemChrome.setEnabledSystemUIMode 관련 코드 제거)

  runApp(
    ProviderScope(child: MyApp(initialScreen: initialScreen)),
  );
}

/// 토큰 상태를 확인하여 초기 화면 결정
Future<Widget> _determineInitialScreen() async {
  final romAuthApi = RomAuthApi();
  final TokenManager tokenManager = TokenManager();
  // refreshToken 불러옴
  final String? refreshToken = await tokenManager.getRefreshToken();

  if (refreshToken == null) return const LoginScreen();
  return await romAuthApi.refreshAccessToken()
      ? const MainScreen()
      : const LoginScreen();
}

/// 앱의 루트 위젯
class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      useInheritedMediaQuery: true,
      minTextAdapt: true,
      child: Builder(builder: (context) {
        return MediaQuery(
          // textScaleFactor: 1.0으로 설정하여 텍스트 크기 조정 방지
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.0)),
          child: MaterialApp(
            title: 'RomRom',
            theme: AppTheme.defaultTheme,
            home: initialScreen,
          ),
        );
      }),
    );
  }
}
