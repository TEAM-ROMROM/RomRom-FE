import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

// 디자인 기준 화면 (iPhone 393x852)
const Size designScreenSize = Size(393, 852);

/// 테스트 화면 크기 고정: 기기 배율 1.0, 테스트 종료 시 복원
void useDesignScreenView(WidgetTester tester, {Size screenSize = designScreenSize}) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = screenSize;
  addTearDown(tester.view.reset);
}

/// 테스트 앱: ScreenUtil 초기화 > MaterialApp(home)
Widget buildDesignScreenApp({required Widget home}) {
  return ScreenUtilInit(
    designSize: designScreenSize,
    builder: (context, child) => MaterialApp(home: home),
  );
}
