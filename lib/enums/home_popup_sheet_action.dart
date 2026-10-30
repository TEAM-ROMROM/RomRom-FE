/// 홈 팝업 바텀시트 결과: 버튼별 사용자 선택 (바깥 탭·뒤로가기는 close)
enum HomePopupSheetAction {
  // "자세히 알아보기" > 링크 이동
  openLink,
  // "다시 보지 않기" > 같은 팝업 영구 미노출
  dismissForever,
  // 닫기 > 다음 앱 실행 때 다시 노출
  close,
}
