/// 신고 사유 공통 형태: 서버 코드·표시 이름·직접 입력 여부 (물품·회원 신고 사유 enum 공용)
abstract interface class ReportReason {
  // 백엔드 사유 코드 (API 전송용)
  int get id;

  // 화면 표시 이름
  String get label;

  // 선택 시 상세 사유 입력란 표시 여부 ('기타' 사유)
  bool get shouldShowExtraCommentInput;
}
