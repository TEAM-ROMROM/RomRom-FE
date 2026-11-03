import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 요청관리 탭 '보낸 요청' 토글 전환 일회성 신호 (교환 요청 화면 '보낸 요청 보기' > 요청관리 탭)
/// 요청관리 탭이 true를 받으면 보낸 요청으로 전환 후 consume()으로 되돌림
class SentRequestsFocusTriggerNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void trigger() => state = true;
  void consume() => state = false;
}

final sentRequestsFocusTriggerProvider = NotifierProvider<SentRequestsFocusTriggerNotifier, bool>(
  SentRequestsFocusTriggerNotifier.new,
);
