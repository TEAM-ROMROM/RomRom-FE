import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// 입력 값이 같으면 이전 위젯 인스턴스 재사용 > 같은 인스턴스는 Flutter가 하위 재빌드 생략
/// 용도: 부모가 자주 재빌드될 때(채팅 메시지 수신 등) 입력이 안 바뀐 무거운 자식 재빌드 차단
/// 입력 비교는 == (목록 순서 포함), 생성 함수가 입력 밖 값을 읽으면 갱신 안 됨 > 읽는 값은 전부 입력에 넣음
class WidgetInstanceCache<T extends Widget> {
  List<Object?>? _lastDependencies;
  T? _cachedWidget;

  /// 입력 같음 > 이전 인스턴스, 다름·처음 > 생성 후 보관
  T resolve(List<Object?> dependencies, T Function() buildWidget) {
    final cachedWidget = _cachedWidget;
    if (cachedWidget != null && listEquals(_lastDependencies, dependencies)) return cachedWidget;
    _lastDependencies = List<Object?>.unmodifiable(dependencies);
    return _cachedWidget = buildWidget();
  }
}
