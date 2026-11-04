/// 보낸 요청 진행 표시 (대기 상태 요청 + 거절 건, 채팅 중·교환완료는 TradeStatus 태그)
enum SentRequestProgress {
  waiting(label: '대기'),
  checked(label: '확인함'),
  rejected(label: '거절됨');

  final String label;

  const SentRequestProgress({required this.label});
}
