import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/debug/debug_config.dart';
import 'package:romrom_fe/debug/debug_overlay_manager.dart';
import 'package:romrom_fe/debug/runtime_url_manager.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/enums/app_update_type.dart';
import 'package:romrom_fe/firebase_options.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/pending_deep_link.dart';
import 'package:romrom_fe/providers/app_version_repository_provider.dart';
import 'package:romrom_fe/screens/app_update_screen.dart';
import 'package:romrom_fe/screens/splash_screen.dart';
import 'package:romrom_fe/services/ad_sdk_initializer.dart';
import 'package:romrom_fe/services/app_initializer.dart';
import 'package:romrom_fe/services/android_navigation_mode.dart';
import 'package:romrom_fe/services/firebase_service.dart';
import 'package:romrom_fe/services/forced_update_lock.dart';
import 'package:romrom_fe/services/push_notification_routing.dart';
import 'package:romrom_fe/services/resume_version_check_service.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/deep_link_router.dart';
import 'package:romrom_fe/utils/device_type.dart';
import 'package:romrom_fe/utils/text_scale_utils.dart';
import 'package:romrom_fe/utils/user_session_lifecycle.dart';

/// 백그라운드에서 알림 설정(최상단에 위치 해야 함)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 광고 동의·SDK 초기화 가장 먼저 시작 (기다리지 않음, 다른 초기화와 병렬 > 첫 광고 요청 앞당김)
  AdSdkInitializer.start();
  if (kDebugMode) {
    await RuntimeUrlManager().init();
  }
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  // 서로 의존 없는 초기화 병렬 (env·SDK <-> Firebase 메시징, Firebase 옵션은 env 미사용)
  await Future.wait([initialize(), _initFirebaseMessaging()]);

  // 시스템 UI 설정 : 네비게이션바 충돌 방지 (EdgeToEdge)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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

  // 첫 프레임(스플래시) 이후 알림 권한 요청 1회 (권한 응답이 스플래시 표시를 막지 않게)
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(FirebaseService().requestNotificationPermission());
  });
}

/// Firebase 메시징 초기화: Firebase 앱 > 백그라운드 핸들러 > 포그라운드 표시 옵션 > 메시지 리스너 (권한 요청 제외)
Future<void> _initFirebaseMessaging() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true, // 배너/알림창 보이기
    badge: true,
    sound: true,
  );
  FirebaseService().registerPushMessageListeners();
}

/// 앱의 루트 위젯
class MyApp extends ConsumerStatefulWidget {
  final bool isGestureMode;

  const MyApp({super.key, required this.isGestureMode});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  final _appLinks = AppLinks();
  // 복귀 버전 확인 (repository provider 경유, 진행 중 중복 차단 상태 유지용 단일 인스턴스)
  late final ResumeVersionCheckService _resumeVersionCheckService = ResumeVersionCheckService(
    fetchServerUpdateType: ref.read(appVersionRepositoryProvider).fetchServerUpdateType,
  );
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 테스트 빌드인 경우 디버그 오버레이 초기화
    if (DebugConfig.isTestBuild) {
      DebugOverlayManager().init(navigatorKey);
    }

    registerSessionEndNavigation(invalidate: ref.invalidate, navigate: _navigateFromRoot, isActive: () => mounted);
    _initAppLinks();
    _initFcmInitialMessage();
  }

  /// 루트 navigator 화면 전환 (세션 종료용, 컨텍스트 없음·해제·강제 업데이트 표시 중 무시)
  void _navigateFromRoot(Widget screen, NavigationTypes type) {
    if (ForcedUpdateLock.instance.isForcedUpdateShowing) return;
    final navigatorContext = navigatorKey.currentContext;
    if (navigatorContext != null && navigatorContext.mounted) {
      navigatorContext.navigateTo(screen: screen, type: type);
    }
  }

  /// 콜드 스타트 알림 탭: 딥링크 게이트에 전달 (메인 진입 전이면 보관 > 메인 진입 후 열림)
  Future<void> _initFcmInitialMessage() async {
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message == null) return;

      debugPrint('[FCM] 콜드 스타트 초기 메시지: ${message.data}');

      routePushNotificationData(message.data);
    } catch (e) {
      debugPrint('[FCM] 콜드 스타트 초기 메시지 처리 실패: $e');
    }
  }

  /// app_links: 콜드 스타트 + 실행 중 링크 > 딥링크 게이트 (로그인·온보딩 중이면 보관)
  Future<void> _initAppLinks() async {
    // 콜드 스타트: 앱이 링크로 열린 경우
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        RomRomDeepLinkRouter.receive(PendingDeepLink(uri: initialUri));
      }
    } catch (e) {
      debugPrint('[AppLinks] 초기 링크 처리 실패: $e');
    }

    // 실행 중 링크 수신
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => RomRomDeepLinkRouter.receive(PendingDeepLink(uri: uri)),
      onError: (e) => debugPrint('[AppLinks] 링크 스트림 오류: $e'),
    );
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
      if (DebugConfig.isTestBuild) {
        DebugOverlayManager().resumeServerLog();
      }
    } else if (state == AppLifecycleState.paused) {
      if (DebugConfig.isTestBuild) {
        DebugOverlayManager().suspendServerLog();
      }
    }
  }

  /// 복귀 버전 확인: 주기 경과 시 서버 확인 > 강제 업데이트면 화면 교체 (이미 표시 중이면 생략)
  Future<void> _checkVersionOnResume() async {
    if (ForcedUpdateLock.instance.isForcedUpdateShowing) return;
    try {
      final UpdateType updateType = await _resumeVersionCheckService.checkIfDue();
      if (updateType != UpdateType.force) return;
      final context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      await AppUpdateScreen.showForcedUpdate(context);
    } catch (error) {
      debugPrint('[app version] resume check failed : $error');
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
              data: MediaQuery.of(context).copyWith(textScaler: clampAppTextScaler(MediaQuery.textScalerOf(context))),
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
