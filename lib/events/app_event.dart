/// 앱 전역 이벤트의 베이스 타입.
///
/// 화면 간 상태 변경을 전파하는 모든 이벤트는 이 클래스를 상속한다.
/// 새 이벤트는 `lib/events/` 폴더에 개별 파일로 추가한다.
///
/// 발행: `AppEventBus.instance.emit(SomeEvent());`
/// 구독: `AppEventBus.instance.on<SomeEvent>().listen((event) { ... });`
abstract class AppEvent {
  const AppEvent();
}
