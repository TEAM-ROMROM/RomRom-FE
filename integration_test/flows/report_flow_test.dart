// 신고 플로우 (기본 계정): 물품 신고(홈 피드 물품 상세), 사용자 신고(채팅 상대 프로필)
// 같은 대상은 중복 신고가 서버에서 거부되므로, 이미 신고한 대상이면 해당 플로우를 건너뜀
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:romrom_fe/enums/error_code.dart';
import 'package:romrom_fe/enums/item_report_reason.dart';
import 'package:romrom_fe/enums/member_report_reason.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/widgets/custom_bottom_navigation_bar.dart';

import '../helpers/common_ui_helper.dart';
import '../helpers/feature_navigation_helper.dart';
import '../helpers/login_helper.dart';
import '../helpers/test_account.dart';

void main() {
  patrolTest('물품 신고: 홈 피드 물품 상세 > 더보기 > 신고하기 > 사유 선택 > 접수 안내 > 홈 복귀', ($) async {
    await launchAppLoggedInAs($, TestAccount.primaryKakao);

    final hasFeedItem = await openFirstHomeFeedItemDetail($);
    if (!hasFeedItem) {
      skipFlow('홈 피드에 신고할 물품이 없음');
      return;
    }

    // 상세 로드 후 우측 상단 더보기 > 신고하기
    final reportMenuTrigger = $(AppIcons.dotsVerticalDefault);
    await reportMenuTrigger.waitUntilVisible(timeout: networkResponseTimeout);
    await selectContextMenuItem($, reportMenuTrigger, '신고하기');

    final isReported = await submitReportWithReason(
      $,
      reasonLabel: ItemReportReason.spamAd.label,
      duplicateErrorMessage: ErrorCode.duplicateReport.koMessage,
    );
    if (!isReported) {
      skipFlow('이미 신고한 물품이라 중복 신고 거부 확인까지만 진행');
      return;
    }

    // 접수 확인 후 상세가 닫히고 홈으로 복귀
    await $(CustomBottomNavigationBar).waitUntilVisible(timeout: networkResponseTimeout);
  });

  patrolTest('사용자 신고: 채팅 상대 프로필 > 더보기 > 신고하기 > 사유 선택 > 접수 안내', ($) async {
    await launchAppLoggedInAs($, TestAccount.primaryKakao);

    final hasChatPartner = await openFirstChatPartnerProfile($);
    if (!hasChatPartner) {
      skipFlow('채팅 상대가 없음 (거래 요청 플로우에서 채팅 시작 선행 필요)');
      return;
    }

    await selectContextMenuItem($, $(AppIcons.dotsVerticalDefault), '신고하기');

    final isReported = await submitReportWithReason(
      $,
      reasonLabel: MemberReportReason.badManners.label,
      duplicateErrorMessage: ErrorCode.duplicateMemberReport.koMessage,
    );
    if (!isReported) {
      skipFlow('이미 신고한 사용자라 중복 신고 거부 확인까지만 진행');
      return;
    }

    // 접수 확인 후 프로필 화면 유지
    expect($(AppIcons.dotsVerticalDefault).exists, isTrue);
  });
}
