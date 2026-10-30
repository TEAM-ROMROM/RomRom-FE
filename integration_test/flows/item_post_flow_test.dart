import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_text_field_phrase.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/enums/navigation_tab_items.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/screens/my_page/my_location_verification_screen.dart';
import 'package:romrom_fe/utils/app_test_keys.dart';
import 'package:romrom_fe/widgets/common/category_chip.dart';
import 'package:romrom_fe/widgets/register_tab/register_tab_item_tile.dart';

import '../helpers/common_ui_helper.dart';
import '../helpers/login_helper.dart';
import '../helpers/test_account.dart';
import '../helpers/test_data.dart';

// 교환 가능 물품 등록 한도 (register_tab_screen: 10개) 도달 시 목록 상단 표시 문구
const String registeredItemLimitCountText = '10/10개';

void main() {
  patrolTest('물품 등록: 사진 업로드 > 카테고리 선택 > 입력 > 등록 완료 > 목록 확인 > 정리 삭제', ($) async {
    await launchAppLoggedInAs($, TestAccount.primaryKakao);

    // 내 물품 탭 (등록 한도 도달 시 등록 불가)
    await openBottomTab($, NavigationTabItems.register);
    if ($(registeredItemLimitCountText).exists) {
      skipFlow('교환 가능 물품이 이미 10개라 등록할 수 없음');
      return;
    }

    // 등록하기 > 등록 폼 (위치 인증 미완료 계정은 인증 화면으로 이동)
    await $('등록하기').tap();
    final isRegisterFormShown = await waitForWantedOrAlternative(
      $,
      wanted: $('0/10'),
      alternative: $(MyLocationVerificationScreen),
    );
    if (!isRegisterFormShown) {
      skipFlow('위치 인증이 안 된 테스트 계정이라 물품 등록 불가 (마이페이지 > 내 위치인증 선행 필요)');
      return;
    }

    // 사진 1장 업로드 (갤러리에 사진 1장 이상 필요)
    await $('0/10').tap();
    await $('앨범에서 선택하기').tap();
    await grantPermissionIfDialogVisible($);
    await $.platform.mobile.pickImageFromGallery(index: 0);
    await $('1/10').waitUntilVisible(timeout: networkResponseTimeout);

    // 제목, 카테고리, 설명
    final itemTitle = createUniqueTestItemTitle();
    await $(AppTestKeys.itemRegisterField(ItemTextFieldPhrase.title)).enterText(itemTitle);

    await $(ItemTextFieldPhrase.category.hintText).tap();
    await $(CategoryChip).containing(ItemCategories.electronics.label).tap();
    await $.pumpAndTrySettle();
    expect($(ItemCategories.electronics.label), findsOneWidget);

    await $(AppTestKeys.itemRegisterField(ItemTextFieldPhrase.description)).enterText(testItemDescription);

    // 물품 상태(단일), 교환 방식(복수 선택 가능)
    await scrollToAndTap($(ItemCondition.slightlyUsed.label));
    await scrollToAndTap($(ItemTradeOption.directTradeOnly.label));

    // 적정 가격 입력 화면 > 완료
    await scrollToAndTap($(AppTestKeys.itemRegisterField(ItemTextFieldPhrase.price)));
    await $(TextField).enterText(testItemPriceInput);
    await $('완료').tap();
    await $.pumpAndTrySettle();

    // 교환 희망 위치 > 현재 위치(권한 없으면 서울시청) 주소 확정 후 선택 완료
    await scrollToAndTap($(AppTestKeys.itemRegisterField(ItemTextFieldPhrase.location)));
    await grantPermissionIfDialogVisible($);
    await $('선택 완료').waitUntilVisible(timeout: networkResponseTimeout);
    await waitUntilGone($, $('국내 위치만 등록할 수 있어요'));
    await $('선택 완료').tap();
    await $.pumpAndTrySettle();

    // 등록 완료 > 안내 > 내 물품 목록에 노출
    await scrollToAndTap($('등록 완료'));
    await waitForText($, '물품이 성공적으로 등록되었습니다.');
    final registeredItemTile = $(RegisterTabItemTile).containing(itemTitle);
    await registeredItemTile.scrollTo();
    expect(registeredItemTile, findsOneWidget);

    // 정리: 방금 등록한 테스트 물품 삭제 (등록 한도 10개 보호)
    await selectContextMenuItem($, registeredItemTile.$(AppIcons.dotsVerticalDefault), '삭제');
    await tapCommonModalButton($, '삭제');
    await waitForText($, '물품이 삭제되었습니다');
  });
}
