import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:patrol/patrol.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/services/app_initializer.dart';

/// 테스트용 앱 위젯 (간단한 버전)
class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(393, 852),
        useInheritedMediaQuery: true,
        minTextAdapt: true,
        child: Builder(
          builder: (context) {
            return SafeArea(
              top: false,
              bottom: Platform.isAndroid,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                child: MaterialApp(title: 'RomRom Test', theme: AppTheme.defaultTheme, home: const LoginScreen()),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 테스트 앱 초기화 및 실행
Future<void> initAndRunTestApp(PatrolIntegrationTester $) async {
  // .env 로드 (테스트 계정 정보 등)
  await dotenv.load(fileName: ".env");

  // 기본 앱 초기화 (Kakao SDK 등)
  try {
    await initialize();
  } catch (e) {
    debugPrint('초기화 오류 (무시 가능): $e');
  }

  // 화면 방향 고정
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  // 테스트 앱 실행
  await $.tester.pumpWidget(const TestApp());
  await $.pumpAndSettle();
}
