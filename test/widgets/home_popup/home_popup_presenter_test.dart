import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/navigation_tab_items.dart';
import 'package:romrom_fe/enums/storage_keys.dart';
import 'package:romrom_fe/exceptions/api_exception.dart';
import 'package:romrom_fe/providers/coach_mark_trigger_provider.dart';
import 'package:romrom_fe/providers/current_tab_index_provider.dart';
import 'package:romrom_fe/providers/home_popup_repository_provider.dart';
import 'package:romrom_fe/repositories/home_popup_repository.dart';
import 'package:romrom_fe/widgets/home_popup/home_popup_presenter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/home_popup_fakes.dart';
import '../../helpers/pump_design_screen.dart';

// 홈 진입 대역 버튼
const String showPopupButtonLabel = 'home loaded';

void main() {
  late FakeHomePopupApi fakeApi;
  late List<String> openedLinkUrls;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // 이미지 없는 팝업 (테스트 중 네트워크 이미지 로딩 회피)
    fakeApi = FakeHomePopupApi()..responseBody = {'homePopup': buildPopupJson(homePopupId: 'popup-a', imageUrl: null)};
    openedLinkUrls = [];
  });

  /// 홈 대역 화면: 버튼 탭 > HomePopupPresenter.showIfNeeded (링크 이동은 기록만)
  Future<ProviderContainer> pumpHomeHost(WidgetTester tester) async {
    useDesignScreenView(tester);
    final container = ProviderContainer(
      overrides: [homePopupRepositoryProvider.overrideWithValue(HomePopupRepository(fakeApi))],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: buildDesignScreenApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => HomePopupPresenter.showIfNeeded(
                    context,
                    ref,
                    openLink: (_, linkUrl) async => openedLinkUrls.add(linkUrl),
                  ),
                  child: const Text(showPopupButtonLabel),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return container;
  }

  Future<void> enterHome(WidgetTester tester) async {
    await tester.tap(find.text(showPopupButtonLabel));
    await tester.pumpAndSettle();
  }

  Future<List<String>> readDismissedPopupIds() async =>
      (await SharedPreferences.getInstance()).getStringList(StorageKeys.dismissedHomePopupIds.key) ?? const [];

  testWidgets('팝업 있음 > 바텀시트에 제목·설명·버튼 3개 노출', (tester) async {
    await pumpHomeHost(tester);
    await enterHome(tester);

    expect(find.text('봄맞이 교환 이벤트'), findsOneWidget);
    expect(find.text('이번 주 교환하면 선물 증정'), findsOneWidget);
    expect(find.text('자세히 알아보기'), findsOneWidget);
    expect(find.text('다시 보지 않기'), findsOneWidget);
    expect(find.text('닫기'), findsOneWidget);
  });

  testWidgets('다시 보지 않기 > 시트 닫힘 + 팝업 id 저장', (tester) async {
    await pumpHomeHost(tester);
    await enterHome(tester);

    await tester.tap(find.text('다시 보지 않기'));
    await tester.pumpAndSettle();

    expect(find.text('봄맞이 교환 이벤트'), findsNothing);
    expect(await readDismissedPopupIds(), ['popup-a']);
  });

  testWidgets('자세히 알아보기 > 시트 닫힘 + 링크 이동, 저장 안 함', (tester) async {
    await pumpHomeHost(tester);
    await enterHome(tester);

    await tester.tap(find.text('자세히 알아보기'));
    await tester.pumpAndSettle();

    expect(find.text('봄맞이 교환 이벤트'), findsNothing);
    expect(openedLinkUrls, ['https://romrom.example.com/event']);
    expect(await readDismissedPopupIds(), isEmpty);
  });

  testWidgets('닫기 > 시트 닫힘, 저장·링크 이동 없음, 같은 세션 재진입 시 미노출', (tester) async {
    await pumpHomeHost(tester);
    await enterHome(tester);

    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    expect(find.text('봄맞이 교환 이벤트'), findsNothing);
    expect(openedLinkUrls, isEmpty);
    expect(await readDismissedPopupIds(), isEmpty);

    await enterHome(tester);
    expect(find.text('봄맞이 교환 이벤트'), findsNothing);
  });

  testWidgets('이동 불가 링크(누락·지원 안 하는 스킴) > 자세히 알아보기 버튼 없음', (tester) async {
    fakeApi.responseBody = {'homePopup': buildPopupJson(imageUrl: null, linkUrl: 'ftp://files.example.com/a')};
    await pumpHomeHost(tester);
    await enterHome(tester);

    expect(find.text('봄맞이 교환 이벤트'), findsOneWidget);
    expect(find.text('자세히 알아보기'), findsNothing);
  });

  testWidgets('팝업 없음(404) > 바텀시트 미노출', (tester) async {
    fakeApi.errorToThrow = ApiException(statusCode: 404, responseBody: '');
    await pumpHomeHost(tester);
    await enterHome(tester);

    expect(find.text('다시 보지 않기'), findsNothing);
  });

  testWidgets('다시 보지 않기한 팝업 > 미노출', (tester) async {
    SharedPreferences.setMockInitialValues({
      StorageKeys.dismissedHomePopupIds.key: ['popup-a'],
    });
    await pumpHomeHost(tester);
    await enterHome(tester);

    expect(find.text('다시 보지 않기'), findsNothing);
  });

  testWidgets('홈 탭 아님·코치마크 대기 중 > 조회 없이 미노출', (tester) async {
    final container = await pumpHomeHost(tester);

    container.read(currentTabIndexProvider.notifier).set(NavigationTabItems.chat.index);
    await enterHome(tester);
    expect(find.text('다시 보지 않기'), findsNothing);

    container.read(currentTabIndexProvider.notifier).set(NavigationTabItems.home.index);
    container.read(coachMarkTriggerProvider.notifier).trigger();
    await enterHome(tester);
    expect(find.text('다시 보지 않기'), findsNothing);

    expect(fakeApi.fetchCount, 0);
  });
}
