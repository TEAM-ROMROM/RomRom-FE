import 'package:romrom_fe/enums/item_report_reason.dart';
import 'package:romrom_fe/enums/member_report_reason.dart';
import 'package:romrom_fe/models/report_reason.dart';

/// 신고 대상 종류: 물품·회원 (대상별 사유 목록·로그 이름)
enum ReportTargetType {
  item(reasons: ItemReportReason.values, logLabel: '신고'),
  member(reasons: MemberReportReason.values, logLabel: '회원 신고');

  // 화면에 표시할 사유 목록 (enum 선언 순서)
  final List<ReportReason> reasons;
  // 실패 로그 접두어: '{logLabel} 요청 중 오류'
  final String logLabel;

  const ReportTargetType({required this.reasons, required this.logLabel});
}
