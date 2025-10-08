import 'dart:io';

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
import 'package:romrom_fe/services/android_navigation_mode.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/services/member_manager_service.dart';

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

  // 안드로이드에서 제스처 모드인지 확인
  bool isGestureMode = false;
  if (Platform.isAndroid) {
    isGestureMode = await AndroidNavigationMode.isGestureMode();
    debugPrint('[main.dart] isGestureMode: $isGestureMode');
  } else {
    // iOS에서는 제스처 모드가 없으므로 기본값 사용
    isGestureMode = true;
  }

  runApp(
    ProviderScope(
      child: MyApp(
        initialScreen: initialScreen,
        isGestureMode: isGestureMode,
      ),
    ),
  );
}

/// 토큰 상태를 확인하여 초기 화면 결정
Future<Widget> _determineInitialScreen() async {
  final romAuthApi = RomAuthApi();
  final TokenManager tokenManager = TokenManager();
  final String? refreshToken = await tokenManager.getRefreshToken();

  if (refreshToken == null) {
    debugPrint('리프레시 토큰 없음: 로그인 화면으로 이동');
    return const LoginScreen();
  }

  final isLoggedIn = await romAuthApi.refreshAccessToken();
  if (!isLoggedIn) {
    debugPrint('토큰 갱신 실패: 로그인 화면으로 이동');
    return const LoginScreen();
  }

  var userInfo = UserInfo();
  try {
    await userInfo.getUserInfo();

    // 로그인된 상태에서 회원 정보 미리 로드
    await MemberManager.getCurrentMember();

    if (userInfo.needsOnboarding) {
      debugPrint('온보딩 필요: ${userInfo.nextOnboardingStep} 단계로 이동');
      return OnboardingFlowScreen(
        initialStep: userInfo.nextOnboardingStep,
      );
    }

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
  final bool isGestureMode;

  const MyApp({
    super.key,
    required this.initialScreen,
    required this.isGestureMode,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      useInheritedMediaQuery: true,
      minTextAdapt: true,
      child: Builder(builder: (context) {
        return SafeArea(
          top: false,
          bottom: !isGestureMode,
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.0)),
            child: MaterialApp(
              title: 'RomRom',
              theme: AppTheme.defaultTheme,
              home: initialScreen,
              // iOS에서 뒤로가기 스와이프 제스처 활성화
              builder: (context, child) {
                return GestureDetector(
                  onTap: () {
                    // 키보드가 열려있을 때 화면을 터치하면 키보드 닫기
                    FocusScope.of(context).unfocus();
                  },
                  child: child,
                );
              },
            ),
          ),
        );
      }),
    );
  }
}
