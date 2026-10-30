// 채팅 교환 완료 플로우 (두 계정): 기본 계정(카카오)이 교환 완료를 요청하고, 보조 계정(구글)이 확인 및 완료
// 두 계정이 같은 채팅방을 가진 상태(거래 요청 수락 후)여야 하고, 각 계정 채팅 탭 첫 번째 방을 대상으로 함
// 파일 순서대로 실행해야 함 (1 > 2)
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/screens/chat_room_screen.dart';
import 'package:romrom_fe/screens/trade_review_screen.dart';
import 'package:romrom_fe/widgets/chat_input_bar.dart';

import '../helpers/common_ui_helper.dart';
import '../helpers/feature_navigation_helper.dart';
import '../helpers/login_helper.dart';
import '../helpers/test_account.dart';

// 상대 요청 카드 대기: 보조 계정이 상대의 요청 메시지를 받기까지 (서버 조회 + 웹소켓)
const Duration tradeRequestCardWait = Duration(seconds: 20);

void main() {
  patrolTest('[1/2] 교환 완료 요청: 채팅방 + 메뉴 > 교환 완료 요청 > 확인 > 요청 카드(요청 취소하기) 노출', ($) async {
    await launchAppLoggedInAs($, TestAccount.primaryKakao);

    final hasChatRoom = await openFirstChatRoom($);
    if (!hasChatRoom) {
      skipFlow('채팅방이 없음 (거래 요청 플로우에서 채팅 시작 선행 필요)');
      return;
    }
    await $(ChatInputBar).waitUntilVisible(timeout: networkResponseTimeout);

    // 첨부(+) 메뉴 > 교환 완료 요청 (이미 완료·진행 중이면 안내 스낵바만 뜸)
    await selectContextMenuItem($, $(ChatInputBar).$(AppIcons.addItemPlus), '교환 완료 요청');
    final requestSheetState = await waitForFirstVisible($, [$('교환을 완료할까요?'), $('이미 교환이 완료되었거나 요청이 진행 중입니다.')]);
    if (requestSheetState == 1) {
      skipFlow('첫 번째 채팅방이 이미 교환 완료 또는 요청 진행 중');
      return;
    }

    // 바텀시트 확인 > 내가 보낸 요청 카드
    await $('확인').tap();
    await waitForText($, '요청 취소하기');
  });

  patrolTest('[2/2] 교환 완료 확인: 상대 요청 카드 > 확인 및 완료하기 > 완료하기 > 후기 화면 > 완료 메시지', ($) async {
    await launchAppLoggedInAs($, TestAccount.secondaryGoogle);

    final hasChatRoom = await openFirstChatRoom($);
    if (!hasChatRoom) {
      skipFlow('채팅방이 없음 (거래 요청 플로우에서 채팅 시작 선행 필요)');
      return;
    }
    await $(ChatRoomScreen).waitUntilVisible(timeout: networkResponseTimeout);

    final hasTradeRequestCard = await isVisibleWithin($, $('확인 및 완료하기'), timeout: tradeRequestCardWait);
    if (!hasTradeRequestCard) {
      skipFlow('상대의 교환 완료 요청이 없음 (1번 선행 필요, 또는 이미 처리됨)');
      return;
    }

    // 확인 및 완료하기 > 되돌릴 수 없음 확인 모달 > 후기 작성 화면
    await $('확인 및 완료하기').tap();
    await tapCommonModalButton($, '완료하기');
    await $(TradeReviewScreen).waitUntilVisible(timeout: networkResponseTimeout);

    // 후기 닫기 > 채팅방에 교환 완료 메시지
    await $(AppIcons.cancel).tap();
    await $.pumpAndTrySettle();
    await waitForText($, '교환이 완료되었습니다!');
    expect($('확인 및 완료하기').exists, isFalse);
  });
}
