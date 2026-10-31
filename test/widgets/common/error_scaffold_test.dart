import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/widgets/common/error_scaffold.dart';
import '../../helpers/pump_design_screen.dart';

/// 시작 화면 > 오류 화면 push (뒤로 가기 pop 확인용)
Future<void> pumpErrorScaffoldFromLauncher(WidgetTester tester, ErrorScaffold errorScaffold) async {
  useDesignScreenView(tester);
  await tester.pumpWidget(
    buildDesignScreenApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => errorScaffold)),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// 노란 '다시 시도' 버튼 배경
Material findRetryButtonMaterial(WidgetTester tester) {
  return tester.widget<Material>(find.ancestor(of: find.text('다시 시도'), matching: find.byType(Material)).first);
}

void main() {
  // 기존 ChatRoomErrorView·ItemDetailErrorView 외형·동작 유지
  group('ErrorScaffold', () {
    testWidgets('채팅방 실패 형태: 문구 + 다시 시도(노란 배경·16 간격·24/12 패딩), 뒤로 가기 콜백 호출', (tester) async {
      var backPressedCount = 0;
      var retryCount = 0;
      await pumpErrorScaffoldFromLauncher(
        tester,
        ErrorScaffold(
          message: '채팅방을 불러오지 못했습니다.',
          onBackPressed: () => backPressedCount++,
          onRetry: () => retryCount++,
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
      expect(scaffold.backgroundColor, AppColors.primaryBlack);
      expect(tester.widget<AppBar>(find.byType(AppBar)).backgroundColor, AppColors.primaryBlack);

      final messageText = tester.widget<Text>(find.text('채팅방을 불러오지 못했습니다.'));
      expect(messageText.style!.color, AppColors.textColorWhite);
      expect(messageText.textAlign, TextAlign.center);

      expect(findRetryButtonMaterial(tester).color, AppColors.primaryYellow);
      expect(tester.widget<Text>(find.text('다시 시도')).style!.color, AppColors.primaryBlack);
      final retryPadding = tester.widget<Padding>(
        find.ancestor(of: find.text('다시 시도'), matching: find.byType(Padding)).first,
      );
      expect(retryPadding.padding, const EdgeInsets.symmetric(horizontal: 24, vertical: 12));
      final messageBottom = tester.getBottomLeft(find.text('채팅방을 불러오지 못했습니다.')).dy;
      final retryTop = tester
          .getTopLeft(find.ancestor(of: find.text('다시 시도'), matching: find.byType(Material)).first)
          .dy;
      expect(retryTop - messageBottom, 16);

      await tester.tap(find.text('다시 시도'));
      expect(retryCount, 1);

      await tester.tap(find.bySemanticsLabel('뒤로 가기'));
      await tester.pumpAndSettle();
      expect(backPressedCount, 1);
      // 콜백 지정 시 기본 pop 미실행
      expect(find.byType(ErrorScaffold), findsOneWidget);
    });

    testWidgets('물품 상세 탈퇴 게시글 형태: 문구만, 다시 시도 없음, 뒤로 가기 기본 pop', (tester) async {
      await pumpErrorScaffoldFromLauncher(tester, const ErrorScaffold(message: '작성자가 탈퇴한 게시글입니다.'));

      expect(find.text('작성자가 탈퇴한 게시글입니다.'), findsOneWidget);
      expect(find.text('다시 시도'), findsNothing);
      expect(find.byIcon(AppIcons.navigateBefore), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('뒤로 가기'));
      await tester.pumpAndSettle();
      expect(find.byType(ErrorScaffold), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('물품 상세 실패 형태: 다시 시도 탭 시 재시도 콜백 1회', (tester) async {
      var retryCount = 0;
      await pumpErrorScaffoldFromLauncher(
        tester,
        ErrorScaffold(message: '물품 정보를 불러오지 못했습니다.', onRetry: () => retryCount++),
      );

      await tester.tap(find.text('다시 시도'));
      expect(retryCount, 1);
    });
  });
}
