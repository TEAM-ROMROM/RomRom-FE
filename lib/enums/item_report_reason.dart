/// 신고 사유 enum (프론트 ↔︎ 백엔드 매핑)
///
/// id    : 백엔드 코드 (ItemReportReason.code)
/// name  : 클라이언트 표시용 한글 이름
/// serverName : 백엔드 enum 이름
///
/// 백엔드 enum 참고:
/// FRAUD(1), ILLEGAL_ITEM(2), INAPPROPRIATE_CONTENT(3), SPAM_AD(4), ETC(5)
///
/// 사용 예시
///   ItemReportReason.values.forEach((reason) => print(reason.name));
///   final codes = selectedReasons.map((e) => e.id).toSet(); // API 전송용
enum ItemReportReason {
  fraud(id: 1, label: '허위 정보/사기 의심', serverName: 'FRAUD'),
  illegalItem(id: 2, label: '불법·금지 물품', serverName: 'ILLEGAL_ITEM'),
  inappropriateContent(id: 3, label: '부적절한 컨텐츠 (욕설·폭력 등)', serverName: 'INAPPROPRIATE_CONTENT'),
  spamAd(id: 4, label: '스팸·광고', serverName: 'SPAM_AD'),
  etc(id: 5, label: '기타', serverName: 'ETC');

  final int id;
  final String label;
  final String serverName;

  const ItemReportReason({required this.id, required this.label, required this.serverName});
} 