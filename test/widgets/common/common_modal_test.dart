import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/device_type.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import '../../helpers/pump_design_screen.dart';

/// 테스트 앱 렌더 > 'open' 탭 시 openModal 실행
Future<void> pumpModalLauncher(WidgetTester tester, {required void Function(BuildContext context) openModal}) async {
  await tester.pumpWidget(
    buildDesignScreenApp(
      home: Builder(
        builder: (launcherContext) => Scaffold(
          body: Center(
            child: ElevatedButton(onPressed: () => openModal(launcherContext), child: const Text('open')),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// 논리 화면 크기 지정 (테스트 종료 시 원복)
void setLogicalScreenSize(WidgetTester tester, Size logicalSize) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = logicalSize;
  addTearDown(tester.view.reset);
}

void main() {
  group('CommonModal 확인 잠금', () {
    testWidgets('비동기 onConfirm 진행 중 확인 2회 탭 → 호출 1회, 로딩 표시', (tester) async {
      final pendingConfirm = Completer<void>();
      var confirmCallCount = 0;

      await pumpModalLauncher(
        tester,
        openModal: (context) => CommonModal.confirm(
          context: context,
          message: '차단하시겠습니까?',
          confirmText: '차단',
          onCancel: () {},
          onConfirm: () {
            confirmCallCount++;
            return pendingConfirm.future;
          },
        ),
      );

      await tester.tap(find.text('차단'));
      await tester.pump();
      expect(find.byType(CommonLoadingIndicator), findsOneWidget);

      // 로딩 중 확인 버튼 자리 재탭
      await tester.tap(find.byType(CommonLoadingIndicator), warnIfMissed: false);
      await tester.pump();

      expect(confirmCallCount, 1);

      pendingConfirm.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('비동기 onConfirm 실패 완료 후 다시 탭 가능', (tester) async {
      var pendingConfirm = Completer<void>();
      var confirmCallCount = 0;

      await pumpModalLauncher(
        tester,
        openModal: (context) => CommonModal.confirm(
          context: context,
          message: '나가시겠습니까?',
          confirmText: '나가기',
          onCancel: () {},
          onConfirm: () {
            confirmCallCount++;
            return pendingConfirm.future;
          },
        ),
      );

      await tester.tap(find.text('나가기'));
      await tester.pump();

      // 실패 완료 > FlutterError 보고 > 잠금 해제
      pendingConfirm.completeError(StateError('network failure'));
      await tester.pump();
      expect(tester.takeException(), isA<StateError>());
      expect(find.byType(CommonLoadingIndicator), findsNothing);

      pendingConfirm = Completer<void>();
      await tester.tap(find.text('나가기'));
      await tester.pump();
      expect(confirmCallCount, 2);

      pendingConfirm.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('동기 onConfirm 2회 탭 → 2회 호출 (기존 동작 유지)', (tester) async {
      var confirmCallCount = 0;

      await pumpModalLauncher(
        tester,
        openModal: (context) =>
            CommonModal.success(context: context, message: '완료되었습니다', onConfirm: () => confirmCallCount++),
      );

      await tester.tap(find.text('확인'));
      await tester.pump();
      await tester.tap(find.text('확인'));
      await tester.pump();

      expect(confirmCallCount, 2);
      expect(find.byType(CommonLoadingIndicator), findsNothing);
    });
  });

  group('CommonModal 확인 진행 중 닫기 차단', () {
    testWidgets('비동기 onConfirm 진행 중 시스템 뒤로가기 → 모달 유지', (tester) async {
      final pendingConfirm = Completer<void>();

      await pumpModalLauncher(
        tester,
        openModal: (context) => CommonModal.confirm(
          context: context,
          message: '채팅방을 나가시겠습니까?',
          confirmText: '나가기',
          onCancel: () {},
          onConfirm: () => pendingConfirm.future,
        ),
      );

      await tester.tap(find.text('나가기'));
      await tester.pump();

      // Android 시스템 back 시뮬레이션 (로딩 스피너 반복 애니메이션 > settle 대신 시간 지정)
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(CommonModal.modalBoxKey), findsOneWidget);

      // 완료 후에는 뒤로가기로 닫힘 (평소 동작 유지)
      pendingConfirm.complete();
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(CommonModal.modalBoxKey), findsNothing);
    });

    testWidgets('비동기 onConfirm 진행 중 취소 탭 → onCancel 미호출', (tester) async {
      final pendingConfirm = Completer<void>();
      var cancelCallCount = 0;

      await pumpModalLauncher(
        tester,
        openModal: (context) => CommonModal.confirm(
          context: context,
          message: '차단하시겠습니까?',
          confirmText: '차단',
          onCancel: () => cancelCallCount++,
          onConfirm: () => pendingConfirm.future,
        ),
      );

      await tester.tap(find.text('차단'));
      await tester.pump();
      await tester.tap(find.text('취소'));
      await tester.pump();

      expect(cancelCallCount, 0);
      expect(find.byKey(CommonModal.modalBoxKey), findsOneWidget);

      pendingConfirm.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('onConfirm이 모달을 먼저 닫고 나중에 완료 → 예외 없음', (tester) async {
      final pendingConfirm = Completer<void>();

      await pumpModalLauncher(
        tester,
        openModal: (context) => CommonModal.confirm(
          context: context,
          message: '로그아웃하시겠어요?',
          confirmText: '로그아웃',
          onCancel: () {},
          onConfirm: () async {
            Navigator.of(context).pop();
            await pendingConfirm.future;
          },
        ),
      );

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();
      expect(find.byKey(CommonModal.modalBoxKey), findsNothing);

      // 모달 해제 후 완료 > mounted 가드로 setState 생략
      pendingConfirm.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('CommonModal 고정 폭', () {
    for (final screenSize in const [designScreenSize, Size(1024, 1366)]) {
      testWidgets('화면 ${screenSize.width.toInt()}x${screenSize.height.toInt()} → 모달 폭 312', (tester) async {
        setLogicalScreenSize(tester, screenSize);
        isTablet = screenSize.width > 600;
        addTearDown(() => isTablet = false);

        await pumpModalLauncher(
          tester,
          openModal: (context) => CommonModal.error(context: context, message: '오류가 발생했습니다', onConfirm: () {}),
        );

        expect(tester.getSize(find.byKey(CommonModal.modalBoxKey)).width, 312);
      });
    }
  });
}
