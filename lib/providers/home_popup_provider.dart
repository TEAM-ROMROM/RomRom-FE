// 홈 공지·이벤트 팝업 Provider (#652)
//
// 종류: 동기 Notifier — 세션당 1회 노출 판정 + "다시 보지 않기" 저장 (로딩 UI 없음)
// 4-레이어 표준: lib/repositories/home_popup_repository.dart + homePopupRepositoryProvider
//               + lib/states/home_popup_state.dart + 이 파일.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/models/apis/objects/home_popup.dart';
import 'package:romrom_fe/providers/home_popup_repository_provider.dart';
import 'package:romrom_fe/states/home_popup_state.dart';

final homePopupProvider = NotifierProvider<HomePopupNotifier, HomePopupState>(HomePopupNotifier.new);

/// 홈 팝업 노출 판정: 세션 1회 확인 > 활성 팝업 조회 > 다시 보지 않기 제외 > 노출 기록
class HomePopupNotifier extends Notifier<HomePopupState> {
  @override
  HomePopupState build() => const HomePopupState();

  /// 이번 세션에 띄울 팝업 1개 확보 (이미 확인한 세션·없음·다시 보지 않기 팝업이면 null)
  Future<HomePopup?> claimPopupForThisSession() async {
    // 세션 확인 표시 먼저 (조회 대기 중 중복 호출 차단)
    if (state.hasCheckedThisSession) return null;
    state = state.copyWith(hasCheckedThisSession: true);

    final repository = ref.read(homePopupRepositoryProvider);
    final popup = await repository.fetchActivePopup();
    if (popup == null) return null;

    final dismissedPopupIds = await repository.loadDismissedPopupIds();
    if (dismissedPopupIds.contains(popup.homePopupId)) return null;

    state = state.copyWith(displayedPopup: popup);
    return popup;
  }

  /// "다시 보지 않기": 팝업 id 로컬 저장 > 다음 실행부터 같은 팝업 미노출 (저장 실패는 로그만)
  Future<void> dismissForever(String popupId) async {
    try {
      await ref.read(homePopupRepositoryProvider).saveDismissedPopupId(popupId);
    } catch (error) {
      debugPrint('[home popup] dismiss save failed : $error');
    }
  }
}
