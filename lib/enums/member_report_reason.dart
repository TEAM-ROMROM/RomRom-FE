/// 회원 신고 사유 enum (프론트 ↔︎ 백엔드 매핑)
///
/// id    : 백엔드 코드 (MemberReportReason.code)
/// label : 클라이언트 표시용 한글 이름
/// serverName : 백엔드 enum 이름
///
/// 백엔드 enum 참고 (가정):
/// BAD_MANNERS(1), FRAUD(2), MISREPRESENTATION(3), NO_SHOW(4), ETC(5)
///
/// 사용 예시
///   MemberReportReason.values.forEach((reason) => print(reason.label));
///   final codes = selectedReasons.map((e) => e.id).toSet(); // API 전송용
enum MemberReportReason {
  badManners(id: 1, label: '비매너/욕설/혐오/성적 발언', serverName: 'BAD_MANNERS'),
  fraud(id: 2, label: '사기 의심/거래 금지 물품', serverName: 'FRAUD'),
  misrepresentation(id: 3, label: '물건 상태 불일치(허위 매물)', serverName: 'MISREPRESENTATION'),
  noShow(id: 4, label: '노쇼(약속 불이행)', serverName: 'NO_SHOW'),
  etc(id: 5, label: '기타(직접 입력)', serverName: 'ETC');

  final int id;
  final String label;
  final String serverName;

  const MemberReportReason({required this.id, required this.label, required this.serverName});
}
