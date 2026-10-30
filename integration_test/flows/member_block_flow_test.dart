// 회원 차단 플로우 (기본 계정): 채팅 상대 프로필에서 차단 > 마이페이지 차단 관리에서 해제
// 파일 순서대로 실행해야 함 (1 > 2), 2번이 해제까지 해서 계정 상태를 원래대로 복구
import 'package:patrol/patrol.dart';
import 'package:romrom_fe/enums/navigation_tab_items.dart';
import 'package:romrom_fe/icons/app_icons.dart';

import '../helpers/common_ui_helper.dart';
import '../helpers/feature_navigation_helper.dart';
import '../helpers/login_helper.dart';
import '../helpers/test_account.dart';

// 프로필 화면에서 차단된 상대에게 붙는 표시
const String blockedProfileLabel = '차단됨';

void main() {
  patrolTest('[1/2] 회원 차단: 채팅 상대 프로필 > 더보기 > 차단하기 > 차단 안내 > 차단됨 표시', ($) async {
    await launchAppLoggedInAs($, TestAccount.primaryKakao);

    final hasChatPartner = await openFirstChatPartnerProfile($);
    if (!hasChatPartner) {
      skipFlow('채팅 상대가 없음 (거래 요청 플로우에서 채팅 시작 선행 필요)');
      return;
    }

    // 이미 차단된 상대면 먼저 해제해 같은 시작 상태로 맞춤
    if ($(blockedProfileLabel).exists) {
      await selectContextMenuItem($, $(AppIcons.dotsVerticalDefault), '차단 해제하기');
      await waitForText($, '차단이 해제되었습니다');
      await waitUntilGone($, $(blockedProfileLabel));
    }

    // 더보기 > 차단하기 (프로필 메뉴는 확인 모달 없이 바로 차단)
    await selectContextMenuItem($, $(AppIcons.dotsVerticalDefault), '차단하기');
    await waitForText($, '사용자를 차단했습니다');
    await $(blockedProfileLabel).waitUntilVisible(timeout: networkResponseTimeout);
  });

  patrolTest('[2/2] 회원 차단 해제: 마이페이지 > 차단 관리 > 차단 해제 > 버튼이 차단하기로 전환', ($) async {
    await launchAppLoggedInAs($, TestAccount.primaryKakao);

    // 마이페이지 > 차단 관리
    await openBottomTab($, NavigationTabItems.myPage);
    await scrollToAndTap($('차단 관리'));

    final hasBlockedMember = await waitForWantedOrAlternative($, wanted: $('차단 해제'), alternative: $('차단한 사용자가 없습니다'));
    if (!hasBlockedMember) {
      skipFlow('차단한 사용자가 없음 (1번 선행 필요)');
      return;
    }

    // 첫 번째 차단 사용자 해제: 버튼 문구가 '차단 해제' > '차단하기'로 전환
    await $('차단 해제').first.tap();
    await waitForText($, '차단하기');
  });
}
