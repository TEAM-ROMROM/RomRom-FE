/// 화면 전환 방식을 정의.
/// [context.navigateTo]의 [type] 파라미터에서 사용.
///
/// 스택 유지: [push], [pushReplacement], [fadePush], [slideUp], [sharedAxisHorizontal]
/// 스택 클리어: [pushAndRemoveUntil], [fadeTransition], [clearStackImmediate]
enum NavigationTypes {
  push, // 기존 화면 위에 추가
  pushReplacement, // 기존 화면을 대체
  pushAndRemoveUntil, // 기존 화면을 지우고 추가
  fadeTransition, // 스택을 지우고 Fade 애니메이션(400ms)으로 전환
  clearStackImmediate, // 스택을 지우고 Fade 애니메이션(400ms)으로 전환 (구 즉시 전환 대체)
  fadePush, // 스택 유지 + Fade 애니메이션
  slideUp, // 스택 유지 + 아래에서 위로 슬라이드 (모달 느낌)
  sharedAxisHorizontal, // 스택 유지 + 수평 SharedAxis (리스트→상세)
}
