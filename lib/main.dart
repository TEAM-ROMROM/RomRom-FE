import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/firebase_options.dart';
import 'package:romrom_fe/models/app_colors.dart';

import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/screens/main_screen.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/services/apis/notification_api.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';
import 'package:romrom_fe/services/app_initializer.dart';
import 'package:romrom_fe/services/android_navigation_mode.dart';
import 'package:romrom_fe/services/firebase_service.dart';
import 'package:romrom_fe/services/notification_service.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/services/member_manager_service.dart';

import 'screens/onboarding/onboarding_flow_screen.dart';

/// 백그라운드에서 알림 설정(최상단에 위치 해야 함)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initialize(); // 초기화 실행

  

  // 시스템 UI 설정 : 네비게이션바 충돌 방지 (EdgeToEdge)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Initialize local notifications plugin (sets default small icon)
  await initNotificationPlugin();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,  // 배너/알림창 보이기
    badge: true,
    sound: true,
  );

  // 알림 권한 요청 설정
  await FirebaseService().setupPushNotifications();

  // FCM 토큰 갱신 감지 및 자동 저장 설정
  _setupFcmTokenRefreshListener();

  final initialScreen = await _determineInitialScreen();

  // 시스템 오버레이 색상 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: AppColors.primaryBlack,
      statusBarColor: Colors.transparent,
    ),
  );

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
      child: MyApp(initialScreen: initialScreen, isGestureMode: isGestureMode),
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
      return OnboardingFlowScreen(initialStep: userInfo.nextOnboardingStep);
    }

    debugPrint('토큰 유효 및 온보딩 완료: 메인 화면으로 이동');
    // 기존 회원 로그인 상태: FCM 토큰 저장
    await FirebaseService().handleFcmToken();
    return MainScreen(key: MainScreen.globalKey);
  } catch (e) {
    debugPrint('사용자 정보 조회 실패: $e');
    return const LoginScreen();
  }
}

/// FCM 토큰 갱신 감지 및 자동 저장 설정
void _setupFcmTokenRefreshListener() {
  final firebaseService = FirebaseService();
  final notificationApi = NotificationApi();

  firebaseService.setupTokenRefreshListener(notificationApi);
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
      child: Builder(
        builder: (context) {
          return SafeArea(
            top: false,
            bottom: Platform.isAndroid ,
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: MaterialApp(
                title: 'RomRom',
                theme: AppTheme.defaultTheme,
                home: initialScreen,
              ),
            ),
          );
        },
      ),
    );
  }
}
