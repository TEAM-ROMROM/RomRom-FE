import 'package:flutter_riverpod/flutter_riverpod.dart';

/// MainScreen 탭 인덱스 Provider (CLAUDE.md 규칙 — GlobalKey 교차호출 대체)
///
/// 종류: 동기 Notifier — 0=홈, 1=요청관리, 2=등록, 3=채팅, 4=마이페이지.
/// 다른 화면이 탭 전환을 요청할 때 [CurrentTabIndexNotifier.set]을 호출한다.
/// GlobalKey<State<MainScreen>> + switchToTab() 패턴을 대체한다.
class CurrentTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) => state = index;
}

final currentTabIndexProvider = NotifierProvider<CurrentTabIndexNotifier, int>(CurrentTabIndexNotifier.new);
