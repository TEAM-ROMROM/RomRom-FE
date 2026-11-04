/// 채팅 메시지 길게 누르기 동작 (복사는 글 선택 툴바 기본 항목)
enum ChatMessageAction {
  // 내 메시지 삭제 (보낸 지 24시간 이내)
  delete(label: '삭제하기', isDestructive: true),
  // 상대 메시지 신고
  report(label: '신고하기', isDestructive: false);

  final String label;
  // 빨간색 표시 여부
  final bool isDestructive;

  const ChatMessageAction({required this.label, required this.isDestructive});
}
