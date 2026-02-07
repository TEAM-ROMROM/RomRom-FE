import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('기본 앱 실행 테스트', ($) async {
    // 가장 간단한 앱 실행
    await $.tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('테스트 앱'))),
      ),
    );
    await $.pumpAndSettle();

    // 텍스트 확인
    expect($('테스트 앱'), findsOneWidget);
  });
}
