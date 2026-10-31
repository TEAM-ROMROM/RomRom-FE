import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/exceptions/api_exception.dart';
import 'package:romrom_fe/providers/home_popup_provider.dart';
import 'package:romrom_fe/providers/home_popup_repository_provider.dart';
import 'package:romrom_fe/repositories/home_popup_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/home_popup_fakes.dart';

void main() {
  late FakeHomePopupApi fakeApi;

  // 앱 실행 1회 = 컨테이너 1개 (다시 보지 않기는 SharedPreferences라 컨테이너 간 유지)
  ProviderContainer createAppSessionContainer() {
    final container = ProviderContainer(
      overrides: [homePopupRepositoryProvider.overrideWithValue(HomePopupRepository(fakeApi))],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeApi = FakeHomePopupApi()..responseBody = {'homePopup': buildPopupJson(homePopupId: 'popup-a')};
  });

  test('첫 확인 > 팝업 반환·노출 기록, 같은 세션 재확인 > null (조회 1회)', () async {
    final container = createAppSessionContainer();
    final notifier = container.read(homePopupProvider.notifier);

    final firstPopup = await notifier.claimPopupForThisSession();
    final secondPopup = await notifier.claimPopupForThisSession();

    expect(firstPopup?.homePopupId, 'popup-a');
    expect(secondPopup, isNull);
    expect(fakeApi.fetchCount, 1);
    final state = container.read(homePopupProvider);
    expect(state.hasCheckedThisSession, isTrue);
    expect(state.displayedPopup?.homePopupId, 'popup-a');
  });

  test('동시 호출 > 조회 1회, 팝업은 한쪽만', () async {
    final notifier = createAppSessionContainer().read(homePopupProvider.notifier);

    final popups = await Future.wait([notifier.claimPopupForThisSession(), notifier.claimPopupForThisSession()]);

    expect(popups.whereType<Object>(), hasLength(1));
    expect(fakeApi.fetchCount, 1);
  });

  test('그냥 닫기 > 다음 실행에서 같은 팝업 다시 노출', () async {
    await createAppSessionContainer().read(homePopupProvider.notifier).claimPopupForThisSession();

    final nextLaunchPopup = await createAppSessionContainer()
        .read(homePopupProvider.notifier)
        .claimPopupForThisSession();

    expect(nextLaunchPopup?.homePopupId, 'popup-a');
  });

  test('다시 보지 않기 저장 > 다음 실행에서 같은 id 미노출', () async {
    final firstLaunchNotifier = createAppSessionContainer().read(homePopupProvider.notifier);
    final popup = await firstLaunchNotifier.claimPopupForThisSession();
    await firstLaunchNotifier.dismissForever(popup!.homePopupId!);

    final nextLaunchPopup = await createAppSessionContainer()
        .read(homePopupProvider.notifier)
        .claimPopupForThisSession();

    expect(nextLaunchPopup, isNull);
  });

  test('다시 보지 않기한 팝업과 다른 id > 노출', () async {
    await createAppSessionContainer().read(homePopupProvider.notifier).dismissForever('popup-a');
    fakeApi.responseBody = {'homePopup': buildPopupJson(homePopupId: 'popup-b')};

    final popup = await createAppSessionContainer().read(homePopupProvider.notifier).claimPopupForThisSession();

    expect(popup?.homePopupId, 'popup-b');
  });

  test('조회 실패(404) > null, 세션 확인 처리 (재조회 안 함)', () async {
    fakeApi.errorToThrow = ApiException(statusCode: 404, responseBody: '');
    final container = createAppSessionContainer();
    final notifier = container.read(homePopupProvider.notifier);

    expect(await notifier.claimPopupForThisSession(), isNull);
    expect(await notifier.claimPopupForThisSession(), isNull);

    expect(fakeApi.fetchCount, 1);
    expect(container.read(homePopupProvider).displayedPopup, isNull);
  });
}
