import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:romrom_fe/enums/navigation_tab_items.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/screens/item_detail_description_screen.dart';
import 'package:romrom_fe/screens/notification_screen.dart';
import 'package:romrom_fe/utils/app_test_keys.dart';
import 'package:romrom_fe/widgets/chat_room_list_item.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/home_feed_item_widget.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';

import 'common_ui_helper.dart';

// 홈 피드 카드 탭 위치: 하단 카드 덱·정보 영역을 피해 위쪽 이미지 영역
const Alignment homeFeedItemTapAlignment = Alignment(0, -0.4);

/// 홈 탭 첫 번째 피드 물품 상세 열기 (피드가 비어 있으면 false)
Future<bool> openFirstHomeFeedItemDetail(PatrolIntegrationTester $) async {
  await openBottomTab($, NavigationTabItems.home);

  final firstFeedItem = $(HomeFeedItemWidget).first;
  final hasFeedItem = await waitForWantedOrAlternative($, wanted: firstFeedItem, alternative: $('물품이 없습니다.'));
  if (!hasFeedItem) return false;

  await firstFeedItem.tap(alignment: homeFeedItemTapAlignment);
  await $(ItemDetailDescriptionScreen).waitUntilVisible(timeout: networkResponseTimeout);
  return true;
}

/// 홈 탭 알림 버튼 > 알림함 열기
Future<void> openNotificationScreen(PatrolIntegrationTester $) async {
  await openBottomTab($, NavigationTabItems.home);
  await $(AppTestKeys.homeNotificationButton).tap();
  await $(NotificationScreen).waitUntilVisible(timeout: networkResponseTimeout);
  await $.pumpAndTrySettle();
}

/// 채팅 탭 첫 번째 채팅방 열기 (채팅방이 없으면 false)
Future<bool> openFirstChatRoom(PatrolIntegrationTester $) async {
  await openBottomTab($, NavigationTabItems.chat);

  final firstChatRoom = $(ChatRoomListItem).first;
  final hasChatRoom = await waitForWantedOrAlternative($, wanted: firstChatRoom, alternative: $('아직 채팅이 없어요'));
  if (!hasChatRoom) return false;

  await firstChatRoom.tap();
  await $.pumpAndTrySettle();
  return true;
}

/// 채팅 탭 첫 번째 채팅방 상대 프로필 열기 (채팅방이 없으면 false)
Future<bool> openFirstChatPartnerProfile(PatrolIntegrationTester $) async {
  await openBottomTab($, NavigationTabItems.chat);

  final firstChatRoom = $(ChatRoomListItem).first;
  final hasChatRoom = await waitForWantedOrAlternative($, wanted: firstChatRoom, alternative: $('아직 채팅이 없어요'));
  if (!hasChatRoom) return false;

  await firstChatRoom.$(UserProfileCircularAvatar).first.tap();
  // 프로필 로드 완료 = 우측 상단 더보기(신고·차단) 메뉴 표시
  await $(AppIcons.dotsVerticalDefault).waitUntilVisible(timeout: networkResponseTimeout);
  return true;
}

/// 신고 화면: 사유 선택 > 신고하기 > 접수 안내 모달 확인 (중복 신고로 거부되면 오류 모달 닫고 false)
/// [duplicateErrorMessage]: 이미 신고한 대상일 때 서버 오류 문구 (ErrorCode.duplicateReport 등)
Future<bool> submitReportWithReason(
  PatrolIntegrationTester $, {
  required String reasonLabel,
  required String duplicateErrorMessage,
}) async {
  await $('신고 사유').waitUntilVisible(timeout: networkResponseTimeout);
  await $(reasonLabel).tap();

  // 앱바 제목과 버튼 문구가 같아 버튼 위젯으로 지정
  await $(CompletionButton).containing('신고하기').tap();

  final isDuplicateReport = await _isDuplicateReportModalShown($, duplicateErrorMessage);
  if (isDuplicateReport) {
    await tapCommonModalButton($, '확인');
    await goBack($);
    return false;
  }

  // 접수 성공: 신고 화면이 닫히고 이전 화면에서 접수 안내 모달
  expect($('신고가 접수되었습니다.'), findsOneWidget);
  await tapCommonModalButton($, '확인');
  return true;
}

/// 신고 직후 모달이 중복 신고 오류인지 판정 (접수 안내면 false)
Future<bool> _isDuplicateReportModalShown(PatrolIntegrationTester $, String duplicateErrorMessage) async {
  return waitForWantedOrAlternative($, wanted: $(duplicateErrorMessage), alternative: $('신고가 접수되었습니다.'));
}
