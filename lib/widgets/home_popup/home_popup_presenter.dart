import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/home_popup_sheet_action.dart';
import 'package:romrom_fe/enums/navigation_tab_items.dart';
import 'package:romrom_fe/providers/coach_mark_trigger_provider.dart';
import 'package:romrom_fe/providers/current_tab_index_provider.dart';
import 'package:romrom_fe/providers/home_popup_provider.dart';
import 'package:romrom_fe/utils/home_popup_link_opener.dart';
import 'package:romrom_fe/widgets/home_popup/home_popup_bottom_sheet.dart';

/// 홈 팝업 노출 진입점: 노출 가능 확인 > 세션 팝업 확보 > 바텀시트 > 선택 처리 (저장·링크 이동)
class HomePopupPresenter {
  const HomePopupPresenter._();

  /// 홈 첫 로딩 이후 호출, 조건 미충족·팝업 없음이면 아무것도 안 함
  static Future<void> showIfNeeded(
    BuildContext context,
    WidgetRef ref, {
    HomePopupLinkOpener openLink = openHomePopupLink,
  }) async {
    if (!canPresentHomePopup(context, ref)) return;

    final homePopupNotifier = ref.read(homePopupProvider.notifier);
    final popup = await homePopupNotifier.claimPopupForThisSession();
    // 조회 대기 중 화면 이동·코치마크 등장 가능 > 다시 확인
    if (popup == null || !context.mounted || !canPresentHomePopup(context, ref)) return;

    final action = await HomePopupBottomSheet.show(context: context, popup: popup);
    final popupId = popup.homePopupId;
    final linkUrl = popup.linkUrl;
    switch (action) {
      case HomePopupSheetAction.dismissForever:
        if (popupId != null) await homePopupNotifier.dismissForever(popupId);
      case HomePopupSheetAction.openLink:
        if (linkUrl != null && context.mounted) await openLink(context, linkUrl);
      case HomePopupSheetAction.close:
        break;
    }
  }

  /// 노출 조건 3개: 홈 탭 선택, 이 화면이 최상단 route(다른 화면·모달 없음), 코치마크 대기 없음
  static bool canPresentHomePopup(BuildContext context, WidgetRef ref) {
    if (!context.mounted) return false;
    final isHomeTabSelected = ref.read(currentTabIndexProvider) == NavigationTabItems.home.index;
    final isTopRoute = ModalRoute.of(context)?.isCurrent ?? true;
    final isCoachMarkPending = ref.read(coachMarkTriggerProvider);
    return isHomeTabSelected && isTopRoute && !isCoachMarkPending;
  }
}
