import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/storage_keys.dart';
import 'package:romrom_fe/exceptions/api_exception.dart';
import 'package:romrom_fe/repositories/home_popup_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/home_popup_fakes.dart';

void main() {
  late FakeHomePopupApi fakeApi;
  late HomePopupRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeApi = FakeHomePopupApi();
    repository = HomePopupRepository(fakeApi);
  });

  group('fetchActivePopup 파싱', () {
    test('{homePopup: {...}} 래퍼 응답 > 전 필드 파싱', () async {
      fakeApi.responseBody = {'homePopup': buildPopupJson()};

      final popup = await repository.fetchActivePopup();

      expect(popup, isNotNull);
      expect(popup!.homePopupId, 'popup-1');
      expect(popup.title, '봄맞이 교환 이벤트');
      expect(popup.description, '이번 주 교환하면 선물 증정');
      expect(popup.imageUrl, 'https://cdn.example.com/popup.png');
      expect(popup.linkUrl, 'https://romrom.example.com/event');
      expect(popup.priority, 10);
      expect(popup.isActive, isTrue);
      expect(popup.startDate, DateTime(2026, 10, 1));
      expect(popup.endDate, DateTime(2026, 11, 30, 23, 59));
    });

    test('래퍼 없이 팝업 객체 그대로 > 파싱', () async {
      fakeApi.responseBody = buildPopupJson(homePopupId: 'popup-root');

      final popup = await repository.fetchActivePopup();

      expect(popup?.homePopupId, 'popup-root');
    });

    test('빈 본문(null)·{homePopup: null}·객체 아닌 본문 > 팝업 없음', () async {
      fakeApi.responseBody = null;
      expect(await repository.fetchActivePopup(), isNull);

      fakeApi.responseBody = {'homePopup': null};
      expect(await repository.fetchActivePopup(), isNull);

      fakeApi.responseBody = ['unexpected'];
      expect(await repository.fetchActivePopup(), isNull);
    });

    test('id 누락 > 팝업 없음', () async {
      fakeApi.responseBody = {'homePopup': buildPopupJson()..remove('homePopupId')};

      expect(await repository.fetchActivePopup(), isNull);
    });

    test('이미지·제목 모두 누락 > 팝업 없음', () async {
      fakeApi.responseBody = buildPopupJson()
        ..remove('imageUrl')
        ..remove('title');

      expect(await repository.fetchActivePopup(), isNull);
    });

    test('isActive false > 팝업 없음, 누락은 서버 판정 신뢰 > 노출', () async {
      fakeApi.responseBody = buildPopupJson()..['isActive'] = false;
      expect(await repository.fetchActivePopup(), isNull);

      fakeApi.responseBody = buildPopupJson()..remove('isActive');
      expect(await repository.fetchActivePopup(), isNotNull);
    });

    test('선택 필드 누락·타입 불일치 > 해당 필드만 null, 팝업은 노출', () async {
      fakeApi.responseBody = {'homePopupId': 'popup-2', 'title': '공지', 'priority': '높음', 'linkUrl': 123};

      final popup = await repository.fetchActivePopup();

      expect(popup?.homePopupId, 'popup-2');
      expect(popup?.imageUrl, isNull);
      expect(popup?.priority, isNull);
      expect(popup?.linkUrl, isNull);
      expect(popup?.startDate, isNull);
    });

    test('404(서버 미배포)·네트워크 오류 > 팝업 없음 (예외 전파 안 함)', () async {
      fakeApi.errorToThrow = ApiException(statusCode: 404, responseBody: '');
      expect(await repository.fetchActivePopup(), isNull);

      fakeApi.errorToThrow = Exception('network down');
      expect(await repository.fetchActivePopup(), isNull);

      fakeApi.errorToThrow = const FormatException('broken json');
      expect(await repository.fetchActivePopup(), isNull);
    });
  });

  group('다시 보지 않기 저장', () {
    test('저장한 id 목록 조회, 같은 id 중복 저장 안 함', () async {
      await repository.saveDismissedPopupId('popup-1');
      await repository.saveDismissedPopupId('popup-1');
      await repository.saveDismissedPopupId('popup-2');

      expect(await repository.loadDismissedPopupIds(), {'popup-1', 'popup-2'});
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getStringList(StorageKeys.dismissedHomePopupIds.key), hasLength(2));
    });

    test('저장 이력 없으면 빈 목록', () async {
      expect(await repository.loadDismissedPopupIds(), isEmpty);
    });
  });
}
