import 'dart:async';

import 'package:romrom_fe/events/app_event.dart';

/// 앱 전역 이벤트 버스.
///
/// 화면 간 상태 변경을 타입 기반으로 전파한다. 발행자와 구독자는 서로를 직접 참조하지 않고
/// 이벤트 타입으로만 연결된다. 새 이벤트는 [AppEvent]를 상속해 `lib/events/`에 추가하면 되며,
/// 버스 자체는 수정할 필요가 없다.
///
/// 발행: `AppEventBus.instance.emit(const TradeCompletedEvent());`
/// 구독: `AppEventBus.instance.on<TradeCompletedEvent>().listen((event) { ... });`
class AppEventBus {
  AppEventBus._internal();

  static final AppEventBus instance = AppEventBus._internal();

  final StreamController<AppEvent> _controller = StreamController<AppEvent>.broadcast();

  /// 이벤트를 broadcast 한다.
  void emit(AppEvent event) {
    _controller.add(event);
  }

  /// 타입 [T]의 이벤트만 필터링한 스트림을 반환한다.
  Stream<T> on<T extends AppEvent>() {
    return _controller.stream.where((event) => event is T).cast<T>();
  }

  void dispose() {
    _controller.close();
  }
}
