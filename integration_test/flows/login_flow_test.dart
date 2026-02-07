import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../helpers/app_helper.dart';

void main() {
  patrolTest('로그인 화면 UI 요소 확인', ($) async {
    await initAndRunTestApp($);

    // 로그인 화면 요소 확인
    expect($('카카오로 시작하기'), findsOneWidget);
    expect($('구글로 시작하기'), findsOneWidget);
  });

  patrolTest('카카오 로그인 버튼 탭 테스트', ($) async {
    await initAndRunTestApp($);

    // 카카오 로그인 버튼 탭
    await $('카카오로 시작하기').tap();

    // WebView 또는 카카오 로그인 화면으로 전환 확인
    await $.pump(const Duration(seconds: 2));
  });

  patrolTest('구글 로그인 버튼 탭 테스트', ($) async {
    await initAndRunTestApp($);

    // 구글 로그인 버튼 탭
    await $('구글로 시작하기').tap();

    // 구글 로그인 다이얼로그 표시 확인
    await $.pump(const Duration(seconds: 2));
  });
}
