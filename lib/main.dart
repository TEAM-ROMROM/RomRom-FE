import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/screens/main_screen.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';
import 'package:romrom_fe/services/app_initializer.dart';
import 'package:romrom_fe/services/token_manager.dart';

import 'screens/onboarding/onboarding_flow_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initialize(); // 초기화 실행
  final initialScreen = await _determineInitialScreen();

  // 시스템 UI 설정 : 네비게이션바 충돌 방지 (EdgeToEdge)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // 시스템 오버레이 색상 설정
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    statusBarColor: Colors.transparent,
  ));

  runApp(
    ProviderScope(child: MyApp(initialScreen: initialScreen)),
  );
}

/// 토큰 상태를 확인하여 초기 화면 결정
Future<Widget> _determineInitialScreen() async {
  final romAuthApi = RomAuthApi();
  final TokenManager tokenManager = TokenManager();
  final String? refreshToken = await tokenManager.getRefreshToken();

  // 리프레시 토큰이 없으면 로그인 화면
  if (refreshToken == null) {
    debugPrint('리프레시 토큰 없음: 로그인 화면으로 이동');
    return const LoginScreen();
  }

  // 토큰으로 로그인 시도
  final isLoggedIn = await romAuthApi.refreshAccessToken();
  if (!isLoggedIn) {
    debugPrint('토큰 갱신 실패: 로그인 화면으로 이동');
    return const LoginScreen();
  }

  // 사용자 정보 확인
  var userInfo = UserInfo();
  try {
    await userInfo.getUserInfo();
    
    // 토큰은 유효하나 필수 정보가 없으면 온보딩으로 이동
    if (userInfo.needsOnboarding) {
      debugPrint('온보딩 필요: ${userInfo.nextOnboardingStep} 단계로 이동');
      return OnboardingFlowScreen(
        initialStep: userInfo.nextOnboardingStep,
      );
    }
    
    // 모든 정보가 있고 토큰도 유효하면 메인 화면
    debugPrint('토큰 유효 및 온보딩 완료: 메인 화면으로 이동');
    return const MainScreen();
  } catch (e) {
    debugPrint('사용자 정보 조회 실패: $e');
    return const LoginScreen();
  }
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
