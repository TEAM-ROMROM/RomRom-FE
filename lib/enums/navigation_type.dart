/// 네비게이션 타입을 정의
enum NavigationType {
  push, // 기존 화면 위에 추가
  pushReplacement, // 기존 화면을 대체
  pushAndRemoveUntil, // 기존 화면을 지우고 추가
}
