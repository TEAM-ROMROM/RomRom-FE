import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/app_update_type.dart';
import 'package:romrom_fe/repositories/app_version_repository.dart';
import 'package:romrom_fe/services/apis/app_version_api.dart';

/// 앱 버전 API 대역: 판정 결과 조절 (null 조회 실패, Completer 응답 지연)
class FakeAppVersionApi implements AppVersionApi {
  UpdateType? updateType = UpdateType.none;
  Completer<UpdateType?>? pendingResponse;

  @override
  Future<UpdateType?> fetchUpdateType() => pendingResponse?.future ?? Future.value(updateType);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeAppVersionApi fakeApi;
  late AppVersionRepository repository;

  setUp(() {
    fakeApi = FakeAppVersionApi();
    repository = AppVersionRepository(fakeApi);
  });

  test('checkUpdateType은 API 판정(none·force)을 그대로 반환', () async {
    expect(await repository.checkUpdateType(), UpdateType.none);
    fakeApi.updateType = UpdateType.force;
    expect(await repository.checkUpdateType(), UpdateType.force);
  });

  test('조회 실패 > fetchServerUpdateType null, checkUpdateType none', () async {
    fakeApi.updateType = null;
    expect(await repository.fetchServerUpdateType(), isNull);
    expect(await repository.checkUpdateType(), UpdateType.none);
  });

  testWidgets('제한 시간(5초) 초과 > null로 통과 (늦은 응답 무시)', (tester) async {
    fakeApi.pendingResponse = Completer<UpdateType?>();
    UpdateType? serverUpdateType = UpdateType.force;
    var isCompleted = false;

    unawaited(
      repository.fetchServerUpdateType().then((updateType) {
        serverUpdateType = updateType;
        isCompleted = true;
      }),
    );
    await tester.pump(AppVersionRepository.versionCheckTimeout - const Duration(milliseconds: 100));
    expect(isCompleted, isFalse);

    await tester.pump(const Duration(milliseconds: 100));
    expect(isCompleted, isTrue);
    expect(serverUpdateType, isNull);

    fakeApi.pendingResponse!.complete(UpdateType.force); // 늦은 응답
    await tester.pump();
    expect(serverUpdateType, isNull);
  });
}
