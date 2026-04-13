import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/debug/debug_config.dart';
import 'package:romrom_fe/debug/debug_overlay_manager.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/enums/app_update_type.dart';
import 'package:romrom_fe/firebase_options.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/app_update_screen.dart';
import 'package:romrom_fe/screens/splash_screen.dart';
import 'package:romrom_fe/services/apis/app_version_api.dart';
import 'package:romrom_fe/services/apis/notification_api.dart';
import 'package:romrom_fe/services/app_initializer.dart';
import 'package:romrom_fe/services/android_navigation_mode.dart';
import 'package:romrom_fe/services/firebase_service.dart';
import 'package:romrom_fe/services/local_notification_service.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/deep_link_router.dart';
import 'package:romrom_fe/utils/device_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 백그라운드에서 알림 설정(최상단에 위치 해야 함)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  await initialize(); // 초기화 실행

  // 시스템 UI 설정 : 네비게이션바 충돌 방지 (EdgeToEdge)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Initialize local notifications plugin (sets default small icon)
  await initNotificationPlugin();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true, // 배너/알림창 보이기
    badge: true,
    sound: true,
  );

  // 알림 권한 요청 설정
  await FirebaseService().setupPushNotifications();

  // FCM 토큰 갱신 감지 및 자동 저장 설정
  _setupFcmTokenRefreshListener();

  // 시스템 오버레이 색상 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(systemNavigationBarColor: AppColors.primaryBlack, statusBarColor: Colors.transparent),
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

  runApp(ProviderScope(child: MyApp(isGestureMode: isGestureMode)));
}

/// FCM 토큰 갱신 감지 및 자동 저장 설정
void _setupFcmTokenRefreshListener() {
  final firebaseService = FirebaseService();
  final notificationApi = NotificationApi();

  firebaseService.setupTokenRefreshListener(notificationApi);
}

/// 앱 전역 navigatorKey (ApiClient 등에서 글로벌 네비게이션에 사용)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 앱의 루트 위젯
class MyApp extends StatefulWidget {
  final bool isGestureMode;

  const MyApp({super.key, required this.isGestureMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static const String _lastVersionCheckKey = 'last_version_check_timestamp';
  static const Duration _checkInterval = Duration(hours: 24);

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 테스트 빌드인 경우 디버그 오버레이 초기화
    if (DebugConfig.isTestBuild) {
      DebugOverlayManager().init(navigatorKey);
    }

    _initAppLinks();
  }

  /// app_links: 콜드 스타트 + 포그라운드 딥링크 처리
  Future<void> _initAppLinks() async {
    // 콜드 스타트: 앱이 링크로 열린 경우
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = navigatorKey.currentContext;
          if (context != null) {
            RomRomDeepLinkRouter.openFromUri(context, initialUri);
          }
        });
      }
    } catch (e) {
      debugPrint('[AppLinks] 초기 링크 처리 실패: $e');
    }

    // 포그라운드: 앱 실행 중 링크 수신
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        RomRomDeepLinkRouter.openFromUri(context, uri);
      }
    }, onError: (e) => debugPrint('[AppLinks] 링크 스트림 오류: $e'));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    if (DebugConfig.isTestBuild) {
      DebugOverlayManager().dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkVersionOnResume();
    }
  }

  Future<void> _checkVersionOnResume() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckMs = prefs.getInt(_lastVersionCheckKey) ?? 0;
      final lastCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckMs);
      final elapsed = DateTime.now().difference(lastCheck);

      if (elapsed < _checkInterval) return; // 24시간 미경과 → 스킵

      final UpdateType updateType = await AppVersionApi().checkUpdateType();

      // 체크 시간 갱신
      await prefs.setInt(_lastVersionCheckKey, DateTime.now().millisecondsSinceEpoch);

      if (updateType == UpdateType.force) {
        final context = navigatorKey.currentContext;
        if (context == null || !context.mounted) return;
        context.navigateTo(screen: const AppUpdateScreen(), type: NavigationTypes.fadeTransition);
      }
    } catch (e) {
      debugPrint('[MyApp] 포그라운드 복귀 버전 체크 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      useInheritedMediaQuery: true,
      minTextAdapt: true,
      splitScreenMode: true,
      child: Builder(
        builder: (context) {
          initDeviceType(context);
          return SafeArea(
            top: false,
            bottom: Platform.isAndroid,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: MaterialApp(
                title: 'RomRom',
                theme: AppTheme.defaultTheme,
                navigatorKey: navigatorKey,
                home: const SplashScreen(),
              ),
            ),
          );
        },
      ),
    );
  }
}
