import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 첫 물건 등록 직후 홈 탭이 코치마크를 표시해야 하는지 나타내는 일회성 신호.
///
/// 등록 탭이 첫 등록을 감지하면 `true`로 set하고 홈 탭으로 전환한다.
/// 홈 탭은 이 값을 watch하여 `true`가 되면 코치마크를 표시한 뒤 `consume()`으로 되돌린다.
/// (GlobalKey로 홈 화면 메서드를 직접 호출하던 방식을 대체)
class CoachMarkTriggerNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void trigger() => state = true;
  void consume() => state = false;
}

final coachMarkTriggerProvider = NotifierProvider<CoachMarkTriggerNotifier, bool>(CoachMarkTriggerNotifier.new);
