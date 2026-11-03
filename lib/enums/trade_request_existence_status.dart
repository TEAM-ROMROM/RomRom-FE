/// 교환 요청 화면: 선택한 내 물품 > 상대 물품 요청 존재 확인 상태
enum TradeRequestExistenceStatus {
  // 확인 중 (선택 탭 대신 로딩, 요청 버튼 비활성)
  checking,
  // 요청 없음 (거래 방식 선택·요청 가능)
  notRequested,
  // 이미 요청함 (보낸 요청 보기 안내)
  alreadyRequested,
  // 확인 실패 (다시 확인 안내, 요청 버튼 비활성)
  checkFailed,
}
