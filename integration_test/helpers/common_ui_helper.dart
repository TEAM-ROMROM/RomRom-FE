import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:romrom_fe/enums/navigation_tab_items.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/custom_bottom_navigation_bar.dart';

// 서버 응답이 필요한 화면·스낵바 최대 대기
const Duration networkResponseTimeout = Duration(seconds: 30);

// 시작 팝업(바텀시트 등) 등장 대기
const Duration startupOverlayWait = Duration(seconds: 3);

// 두 조건 중 먼저 만족하는 쪽을 찾는 폴링 간격
const Duration conditionPollInterval = Duration(milliseconds: 500);

// 로그인 직후 홈에서 가리는 팝업의 닫기 버튼 문구: 알림 안내 바텀시트 2종, 리뷰 요청 팝업
const List<String> startupOverlayDismissLabels = ['나중에 하기', '7일 동안 보지 않기', '나중에'];

/// 조건 불충족으로 플로우를 건너뜀: 사유 로그 + 테스트 skip 표시 (호출부에서 바로 return)
void skipFlow(String reason) {
  debugPrint('[e2e skip] $reason');
  markTestSkipped(reason);
}

/// 로그인 직후 팝업 정리 (알림 안내 바텀시트, 리뷰 요청 팝업)
Future<void> dismissStartupOverlays(PatrolIntegrationTester $) async {
  // 홈 피드 로딩 후 바텀시트가 늦게 뜰 수 있어 잠시 대기
  await $.pumpAndTrySettle(timeout: startupOverlayWait);
  for (final dismissLabel in startupOverlayDismissLabels) {
    final dismissButton = $(dismissLabel);
    if (!dismissButton.exists) continue;
    await dismissButton.tap();
    await $.pumpAndTrySettle();
  }
}

/// 시스템 권한 팝업이 떠 있으면 허용 (위치·사진 등)
Future<void> grantPermissionIfDialogVisible(PatrolIntegrationTester $) async {
  final isDialogVisible = await $.platform.mobile.isPermissionDialogVisible(timeout: startupOverlayWait);
  if (isDialogVisible) await $.platform.mobile.grantPermissionWhenInUse();
}

/// 하단 탭 이동 (탭 이름이 각 화면 제목과 겹쳐 하단 바 안에서만 탐색)
Future<void> openBottomTab(PatrolIntegrationTester $, NavigationTabItems tab) async {
  await $(CustomBottomNavigationBar).$(tab.title).tap();
  await $.pumpAndTrySettle();
}

/// 앱바·화면 좌상단 뒤로가기 아이콘 탭
Future<void> goBack(PatrolIntegrationTester $) async {
  await $(AppIcons.navigateBefore).first.tap();
  await $.pumpAndTrySettle();
}

/// 화면 스크롤로 대상을 보이게 한 뒤 탭
Future<void> scrollToAndTap(PatrolFinder target) async {
  await target.scrollTo();
  await target.tap();
}

/// 스낵바·안내 문구 등장 대기 (서버 응답 포함)
Future<void> waitForText(PatrolIntegrationTester $, String text, {Duration timeout = networkResponseTimeout}) async {
  await $(text).waitUntilVisible(timeout: timeout);
}

/// 공통 모달(CommonModal) 안의 버튼 탭: 확인·취소·삭제 등 문구로 지정
Future<void> tapCommonModalButton(PatrolIntegrationTester $, String buttonText) async {
  final modalBox = $(CommonModal.modalBoxKey);
  await modalBox.waitUntilVisible(timeout: networkResponseTimeout);
  await modalBox.$(buttonText).tap();
  await $.pumpAndTrySettle();
}

/// 점 3개(더보기) 컨텍스트 메뉴 열기 > 항목 문구 탭 (메뉴 오버레이는 트리 맨 뒤라 마지막 일치 항목)
Future<void> selectContextMenuItem(PatrolIntegrationTester $, PatrolFinder menuTrigger, String itemTitle) async {
  await menuTrigger.tap();
  final menuItem = $(itemTitle).last;
  await menuItem.waitUntilVisible();
  await menuItem.tap();
  await $.pumpAndTrySettle();
}

/// 대상이 화면에서 사라질 때까지 대기 (로딩 표시·안내 문구 해제 확인, 시간 초과 시 실패)
Future<void> waitUntilGone(
  PatrolIntegrationTester $,
  PatrolFinder target, {
  Duration timeout = networkResponseTimeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (target.exists) {
    if (DateTime.now().isAfter(deadline)) {
      throw TestFailure('Widget still visible after ${timeout.inSeconds}s: ${target.finder}');
    }
    await $.pump(conditionPollInterval);
  }
}

/// 제한 시간 안에 대상이 나타나는지 확인 (시간 초과 시 실패하지 않고 false: 선행 데이터 유무 판정용)
Future<bool> isVisibleWithin(
  PatrolIntegrationTester $,
  PatrolFinder target, {
  Duration timeout = networkResponseTimeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (target.visible) return true;
    await $.pump(conditionPollInterval);
  }
  return false;
}

/// 후보 중 먼저 나타난 화면 상태의 index 반환 (여러 분기 중 하나로 확정되는 화면 대기, 없으면 실패)
Future<int> waitForFirstVisible(
  PatrolIntegrationTester $,
  List<PatrolFinder> candidates, {
  Duration timeout = networkResponseTimeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    for (var candidateIndex = 0; candidateIndex < candidates.length; candidateIndex++) {
      if (candidates[candidateIndex].visible) return candidateIndex;
    }
    await $.pump(conditionPollInterval);
  }
  throw TestFailure('None of ${candidates.length} expected screen states appeared within ${timeout.inSeconds}s');
}

/// 두 화면 상태 중 먼저 나타난 쪽 판정: wanted 가 먼저면 true, alternative 가 먼저면 false
Future<bool> waitForWantedOrAlternative(
  PatrolIntegrationTester $, {
  required PatrolFinder wanted,
  required PatrolFinder alternative,
  Duration timeout = networkResponseTimeout,
}) async {
  final firstVisibleIndex = await waitForFirstVisible($, [wanted, alternative], timeout: timeout);
  return firstVisibleIndex == 0;
}
