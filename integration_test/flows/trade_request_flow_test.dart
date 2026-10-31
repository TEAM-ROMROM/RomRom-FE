// 거래 요청 플로우 (두 계정): 기본 계정(카카오)이 보내고, 보조 계정(구글)이 받아서 수락/거절
// 앱에는 별도 수락·거절 버튼이 없음: 수락 = 받은 요청 상세의 '채팅하기'(채팅 시작), 거절 = 받은 요청 카드 메뉴의 '삭제'
// 파일 순서대로 실행해야 함 (1 > 2 > 3), 2·3번은 보조 계정이 1번 대상 물품의 주인이거나 이미 받은 요청이 있어야 진행
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/enums/navigation_tab_items.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/screens/chat_room_screen.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/utils/app_test_keys.dart';
import 'package:romrom_fe/widgets/chat_input_bar.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/request_list_item_card_widget.dart';
import 'package:romrom_fe/widgets/sent_request_item_card.dart';
import 'package:romrom_fe/widgets/trade_request_trade_option_selector.dart';

import '../helpers/common_ui_helper.dart';
import '../helpers/feature_navigation_helper.dart';
import '../helpers/login_helper.dart';
import '../helpers/test_account.dart';

// 받은 요청이 없을 때 목록 안내 문구
const String noReceivedRequestText = '진행 중인 요청이 없습니다';

/// 요청관리 탭 받은 요청 첫 카드 반환 (받은 요청이 없으면 null)
Future<PatrolFinder?> findFirstReceivedRequestCard(PatrolIntegrationTester $) async {
  await openBottomTab($, NavigationTabItems.requestManagement);

  final firstReceivedRequest = $(RequestListItemCardWidget).first;
  final hasReceivedRequest = await waitForWantedOrAlternative(
    $,
    wanted: firstReceivedRequest,
    alternative: $(noReceivedRequestText),
  );
  return hasReceivedRequest ? firstReceivedRequest : null;
}

void main() {
  patrolTest('[1/3] 요청 보내기: 홈 물품 상세 > 요청하기 > 교환 방식 선택 > 전송 > 보낸 요청 확인', ($) async {
    await launchAppLoggedInAs($, TestAccount.primaryKakao);

    // 홈 피드 첫 물품 상세 > 요청하기
    final hasFeedItem = await openFirstHomeFeedItemDetail($);
    if (!hasFeedItem) {
      skipFlow('홈 피드에 요청할 다른 회원 물품이 없음');
      return;
    }
    await $('요청하기').waitUntilVisible(timeout: networkResponseTimeout);
    await $('요청하기').tap();

    // 요청하기 화면 상태 분기: 요청 가능 / 이미 요청함 / 내 물품 없음
    final requestScreenState = await waitForFirstVisible($, [$('교환 방식 선택'), $('이미 교환을 요청한 물품입니다.'), $('등록된 물품이 없습니다')]);
    if (requestScreenState == 1) {
      skipFlow('이미 교환을 요청한 물품 (이전 실행의 요청이 남아 있음, 받는 쪽 거절/삭제 후 재실행)');
      return;
    }
    if (requestScreenState == 2) {
      skipFlow('요청에 쓸 내 교환 가능 물품이 없음 (물품 등록 플로우 선행 필요)');
      return;
    }

    // 교환 방식 선택 > 요청하기 > 전송 안내 (실패 모달이면 즉시 실패)
    await $(TradeRequestTradeOptionSelector).$(ItemTradeOption.directTradeOnly.label).tap();
    await $(AppTestKeys.tradeRequestSubmitButton).tap();
    final submitResultIndex = await waitForFirstVisible($, [$('교환 요청이 전송되었습니다.'), $(CommonModal.modalBoxKey)]);
    expect(submitResultIndex, 0, reason: '교환 요청 전송이 오류 모달로 거부됨');

    // 요청 관리 > 보낸 요청에 노출
    await goBack($);
    await openBottomTab($, NavigationTabItems.requestManagement);
    await $('보낸 요청').first.tap();
    await $(SentRequestItemCard).first.waitUntilVisible(timeout: networkResponseTimeout);
  });

  patrolTest('[2/3] 요청 받기 수락: 받은 요청 > 물품 상세 > 채팅하기 > 채팅방 진입', ($) async {
    await launchAppLoggedInAs($, TestAccount.secondaryGoogle);

    final firstReceivedRequest = await findFirstReceivedRequestCard($);
    if (firstReceivedRequest == null) {
      skipFlow('보조 계정이 받은 요청이 없음 (1번 요청이 보조 계정 물품 대상이 아니었음)');
      return;
    }

    // 받은 요청 카드 > 상대 물품 상세 (받은 요청이라 채팅하기 버튼 노출)
    await firstReceivedRequest.tap();
    await $(ItemDetailDescriptionScreen).waitUntilVisible(timeout: networkResponseTimeout);

    // 채팅하기 > 채팅방 (입력창 노출 = 채팅 시작)
    await $('채팅하기').waitUntilVisible(timeout: networkResponseTimeout);
    await $('채팅하기').tap();
    await $(ChatRoomScreen).waitUntilVisible(timeout: networkResponseTimeout);
    await $(ChatInputBar).waitUntilVisible(timeout: networkResponseTimeout);
  });

  patrolTest('[3/3] 요청 받기 거절: 받은 요청 카드 메뉴 > 삭제 > 확인 > 삭제 안내', ($) async {
    await launchAppLoggedInAs($, TestAccount.secondaryGoogle);

    final firstReceivedRequest = await findFirstReceivedRequestCard($);
    if (firstReceivedRequest == null) {
      skipFlow('보조 계정이 받은 요청이 없음 (2번에서 받은 요청이 처리됐거나 1번 대상이 아니었음)');
      return;
    }

    // 카드 더보기 > 삭제 > 확인 모달
    await selectContextMenuItem($, firstReceivedRequest.$(AppIcons.dotsVerticalDefault), '삭제');
    await tapCommonModalButton($, '삭제');
    await waitForText($, '요청을 삭제했습니다.');
  });
}
