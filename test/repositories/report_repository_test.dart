import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/repositories/report_repository.dart';
import 'package:romrom_fe/services/apis/report_api.dart';

/// 신고 API 대역: 마지막 신고 인자 기록
class FakeReportApi implements ReportApi {
  String? lastReportedItemId;
  Set<int>? lastItemReportReasons;
  String? lastTargetMemberId;
  Set<int>? lastMemberReportReasons;
  String? lastExtraComment;

  @override
  Future<void> reportItem({required String itemId, required Set<int> itemReportReasons, String? extraComment}) async {
    lastReportedItemId = itemId;
    lastItemReportReasons = itemReportReasons;
    lastExtraComment = extraComment;
  }

  @override
  Future<void> reportMember({
    required String targetMemberId,
    required Set<int> memberReportReasons,
    String? extraComment,
  }) async {
    lastTargetMemberId = targetMemberId;
    lastMemberReportReasons = memberReportReasons;
    lastExtraComment = extraComment;
  }
}

void main() {
  group('ReportRepository', () {
    late FakeReportApi fakeApi;
    late ReportRepository repository;

    setUp(() {
      fakeApi = FakeReportApi();
      repository = ReportRepository(fakeApi);
    });

    test('reportItem은 물품 id·사유·추가 의견을 그대로 전달', () async {
      await repository.reportItem(itemId: 'item-1', itemReportReasons: {1, 3}, extraComment: '광고');

      expect(fakeApi.lastReportedItemId, 'item-1');
      expect(fakeApi.lastItemReportReasons, {1, 3});
      expect(fakeApi.lastExtraComment, '광고');
    });

    test('reportMember는 대상 회원 id·사유·추가 의견을 그대로 전달', () async {
      await repository.reportMember(targetMemberId: 'member-1', memberReportReasons: {2}, extraComment: '');

      expect(fakeApi.lastTargetMemberId, 'member-1');
      expect(fakeApi.lastMemberReportReasons, {2});
      expect(fakeApi.lastExtraComment, '');
    });
  });
}
