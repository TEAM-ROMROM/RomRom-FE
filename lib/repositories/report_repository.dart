import 'package:romrom_fe/services/apis/report_api.dart';

/// 신고 저장소: 물품 신고, 회원 신고 (ReportApi 래핑, UI 모름)
class ReportRepository {
  final ReportApi _api;

  ReportRepository(this._api);

  /// 물품 신고 (사유 id 집합 + 추가 의견, 빈 의견은 미전송)
  Future<void> reportItem({required String itemId, required Set<int> itemReportReasons, String? extraComment}) {
    return _api.reportItem(itemId: itemId, itemReportReasons: itemReportReasons, extraComment: extraComment);
  }

  /// 회원 신고 (사유 id 집합 + 추가 의견, 빈 의견은 미전송)
  Future<void> reportMember({
    required String targetMemberId,
    required Set<int> memberReportReasons,
    String? extraComment,
  }) {
    return _api.reportMember(
      targetMemberId: targetMemberId,
      memberReportReasons: memberReportReasons,
      extraComment: extraComment,
    );
  }
}
