// 알림 플로우 (기본 계정): 알림 읽음, 개별 삭제, 전체 삭제
// 알림이 있는 계정이어야 진행 (다른 플로우의 거래 요청·좋아요 등으로 생성), 전체 삭제가 마지막이라 순서 유지
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:romrom_fe/enums/navigation_tab_items.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/screens/notification_screen.dart';
import 'package:romrom_fe/utils/app_test_keys.dart';
import 'package:romrom_fe/widgets/notification_item_widget.dart';

import '../helpers/common_ui_helper.dart';
import '../helpers/feature_navigation_helper.dart';
import '../helpers/login_helper.dart';
import '../helpers/test_account.dart';

// 알림 탭 이동 후 알림함으로 돌아오기 위한 뒤로가기 최대 횟수
const int maxBackStepsToNotificationScreen = 3;

/// 알림함 열기 (알림이 하나도 없으면 false)
Future<bool> openNotificationScreenWithItems(PatrolIntegrationTester $) async {
  await openNotificationScreen($);
  return waitForWantedOrAlternative($, wanted: $(NotificationItemWidget).first, alternative: $('알림이 없습니다'));
}

/// 홈 알림 버튼에 미확인 배지가 있는지 (배지 없음 = 기본 알림 아이콘)
bool hasUnreadNotificationBadge(PatrolIntegrationTester $) {
  return !$(AppTestKeys.homeNotificationButton).$(AppIcons.alert).exists;
}

void main() {
  patrolTest('알림 읽음: 알림 탭 > 알림함 복귀 > 홈 복귀 시 미확인 배지 해제', ($) async {
    await launchAppLoggedInAs($, TestAccount.primaryKakao);

    // 홈 알림 버튼 상태 기록 후 알림함 진입
    await openBottomTab($, NavigationTabItems.home);
    final hadUnreadBadge = hasUnreadNotificationBadge($);
    final hasNotification = await openNotificationScreenWithItems($);
    if (!hasNotification) {
      skipFlow('알림이 없는 계정');
      return;
    }

    // 알림 탭: 읽음 처리 + 딥링크 이동 > 이동했으면 알림함으로 복귀
    await $(NotificationItemWidget).first.tap();
    await $.pumpAndTrySettle();
    for (var backStep = 0; backStep < maxBackStepsToNotificationScreen; backStep++) {
      if ($(NotificationScreen).visible) break;
      await goBack($);
    }
    await $(NotificationScreen).waitUntilVisible();

    // 알림함 닫기 > 홈: 전체 읽음 반영으로 배지 없는 기본 아이콘
    await goBack($);
    await $(AppTestKeys.homeNotificationButton).$(AppIcons.alert).waitUntilVisible(timeout: networkResponseTimeout);
    if (!hadUnreadBadge) debugPrint('[e2e note] 시작 시 이미 미확인 알림이 없어 읽음 전환은 검증하지 못함');
  });

  patrolTest('알림 삭제: 알림 더보기 > 삭제 > 삭제 안내', ($) async {
    await launchAppLoggedInAs($, TestAccount.primaryKakao);

    final hasNotification = await openNotificationScreenWithItems($);
    if (!hasNotification) {
      skipFlow('알림이 없는 계정');
      return;
    }

    final firstNotification = $(NotificationItemWidget).first;
    await selectContextMenuItem($, firstNotification.$(AppIcons.dotsVerticalDefault), '삭제');
    await waitForText($, '알림이 삭제되었습니다.');
  });

  patrolTest('알림 전체 삭제: 헤더 휴지통 > 전체 삭제 안내 > 빈 목록 문구', ($) async {
    await launchAppLoggedInAs($, TestAccount.primaryKakao);

    final hasNotification = await openNotificationScreenWithItems($);
    if (!hasNotification) {
      skipFlow('알림이 없는 계정');
      return;
    }

    // 헤더 휴지통(알림 항목 메뉴는 닫혀 있어 헤더 것만 존재)
    await $(AppIcons.trash).first.tap();
    await waitForText($, '모든 알림이 삭제되었습니다.');
    await waitForText($, '알림이 없습니다');
    expect($(NotificationItemWidget).exists, isFalse);
  });
}
