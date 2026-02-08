import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers/app_helper.dart';

void main() {
  patrolTest('로그인 화면 표시 확인', ($) async {
    await initAndRunTestApp($);

    // 로그인 화면 요소 확인
    expect($('카카오로 시작하기'), findsOneWidget);
  });

  patrolTest('카카오 로그인 버튼 존재 확인', ($) async {
    await initAndRunTestApp($);

    // 카카오 로그인 버튼이 화면에 표시되는지 확인
    expect($('카카오로 시작하기'), findsOneWidget);
  });

  patrolTest('구글 로그인 버튼 존재 확인', ($) async {
    await initAndRunTestApp($);

    // 구글 로그인 버튼이 화면에 표시되는지 확인
    expect($('구글로 시작하기'), findsOneWidget);
  });
}
