import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_report_reason.dart';
import 'package:romrom_fe/enums/member_report_reason.dart';
import 'package:romrom_fe/enums/report_target_type.dart';
import 'package:romrom_fe/providers/report_repository_provider.dart';
import 'package:romrom_fe/repositories/report_repository.dart';
import 'package:romrom_fe/screens/report_screen.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import '../helpers/pump_design_screen.dart';

/// 신고 저장소 대역: 호출 인자 기록, [isFailing]이면 throw
class RecordingReportRepository implements ReportRepository {
  bool isFailing = false;
  String? reportedItemId;
  Set<int>? itemReportReasons;
  String? reportedMemberId;
  Set<int>? memberReportReasons;
  String? extraComment;

  @override
  Future<void> reportItem({required String itemId, required Set<int> itemReportReasons, String? extraComment}) async {
    if (isFailing) throw Exception('boom');
    reportedItemId = itemId;
    this.itemReportReasons = itemReportReasons;
    this.extraComment = extraComment;
  }

  @override
  Future<void> reportMember({
    required String targetMemberId,
    required Set<int> memberReportReasons,
    String? extraComment,
  }) async {
    if (isFailing) throw Exception('boom');
    reportedMemberId = targetMemberId;
    this.memberReportReasons = memberReportReasons;
    this.extraComment = extraComment;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 시작 화면 > 신고 화면 push, pop 결과를 [onReportResult]로 전달
Future<void> pumpReportScreenFromLauncher(
  WidgetTester tester, {
  required ReportScreen reportScreen,
  required RecordingReportRepository reportRepository,
  required void Function(bool? isReported) onReportResult,
}) async {
  useDesignScreenView(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [reportRepositoryProvider.overrideWithValue(reportRepository)],
      child: buildDesignScreenApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => onReportResult(await context.navigateTo<bool>(screen: reportScreen)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> tapSubmitButton(WidgetTester tester) async {
  await tester.tap(find.byType(CompletionButton));
  await tester.pumpAndSettle();
}

void main() {
  group('ReportScreen 물품 신고', () {
    testWidgets('물품 사유 목록 렌더 > 사유 선택 후 신고 > reportItem 호출 + pop(true)', (tester) async {
      final reportRepository = RecordingReportRepository();
      bool? reportResult;
      await pumpReportScreenFromLauncher(
        tester,
        reportScreen: const ReportScreen.item(itemId: 'item-1'),
        reportRepository: reportRepository,
        onReportResult: (isReported) => reportResult = isReported,
      );

      expect(find.text('신고하기'), findsNWidgets(2)); // 앱바 제목 + 하단 버튼
      for (final reason in ItemReportReason.values) {
        expect(find.text(reason.label), findsOneWidget);
      }
      expect(find.text(MemberReportReason.badManners.label), findsNothing);

      await tester.tap(find.text(ItemReportReason.fraud.label));
      await tester.pump();
      await tapSubmitButton(tester);

      expect(reportRepository.reportedItemId, 'item-1');
      expect(reportRepository.itemReportReasons, {ItemReportReason.fraud.id});
      expect(reportRepository.extraComment, '');
      expect(reportRepository.reportedMemberId, isNull);
      expect(reportResult, isTrue);
      expect(find.byType(ReportScreen), findsNothing);
    });

    test('대상별 생성자 > 대상 종류·ID 매핑', () {
      const itemReportScreen = ReportScreen.item(itemId: 'item-1');
      const memberReportScreen = ReportScreen.member(memberId: 'member-1');

      expect(itemReportScreen.targetType, ReportTargetType.item);
      expect(itemReportScreen.targetId, 'item-1');
      expect(memberReportScreen.targetType, ReportTargetType.member);
      expect(memberReportScreen.targetId, 'member-1');
    });

    testWidgets('사유 미선택이면 신고 버튼 비활성', (tester) async {
      await pumpReportScreenFromLauncher(
        tester,
        reportScreen: const ReportScreen(targetType: ReportTargetType.item, targetId: 'item-1'),
        reportRepository: RecordingReportRepository(),
        onReportResult: (_) {},
      );

      expect(tester.widget<CompletionButton>(find.byType(CompletionButton)).isEnabled, isFalse);
    });

    testWidgets('신고 실패 > 오류 안내 후 화면 유지 (pop 없음)', (tester) async {
      final reportRepository = RecordingReportRepository()..isFailing = true;
      bool isPopped = false;
      await pumpReportScreenFromLauncher(
        tester,
        reportScreen: const ReportScreen(targetType: ReportTargetType.item, targetId: 'item-1'),
        reportRepository: reportRepository,
        onReportResult: (_) => isPopped = true,
      );

      await tester.tap(find.text(ItemReportReason.spamAd.label));
      await tester.pump();
      // 오류 모달 애니메이션이 끝나지 않아 pumpAndSettle 대신 고정 pump
      await tester.tap(find.byType(CompletionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(isPopped, isFalse);
      expect(find.byType(ReportScreen), findsOneWidget);
    });
  });

  group('ReportScreen 회원 신고', () {
    testWidgets('회원 사유 목록 렌더 > 기타 선택 시 입력란 > reportMember 호출 + pop(true)', (tester) async {
      final reportRepository = RecordingReportRepository();
      bool? reportResult;
      await pumpReportScreenFromLauncher(
        tester,
        reportScreen: const ReportScreen.member(memberId: 'member-1'),
        reportRepository: reportRepository,
        onReportResult: (isReported) => reportResult = isReported,
      );

      for (final reason in MemberReportReason.values) {
        expect(find.text(reason.label), findsOneWidget);
      }
      expect(find.text(ItemReportReason.fraud.label), findsNothing);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text(MemberReportReason.etc.label));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), '  약속 장소에 오지 않음  ');
      await tester.pump();
      expect(find.text('${'  약속 장소에 오지 않음  '.length}/300'), findsOneWidget);

      await tapSubmitButton(tester);

      expect(reportRepository.reportedMemberId, 'member-1');
      expect(reportRepository.memberReportReasons, {MemberReportReason.etc.id});
      expect(reportRepository.extraComment, '약속 장소에 오지 않음');
      expect(reportRepository.reportedItemId, isNull);
      expect(reportResult, isTrue);
    });
  });
}
