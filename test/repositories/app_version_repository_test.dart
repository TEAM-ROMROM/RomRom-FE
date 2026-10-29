import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/app_update_type.dart';
import 'package:romrom_fe/repositories/app_version_repository.dart';
import 'package:romrom_fe/services/apis/app_version_api.dart';

/// 앱 버전 API 대역: 업데이트 판정 결과 조절
class FakeAppVersionApi implements AppVersionApi {
  UpdateType updateType = UpdateType.none;

  @override
  Future<UpdateType> checkUpdateType() async => updateType;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('AppVersionRepository.checkUpdateType은 API 판정(none·force)을 그대로 반환', () async {
    final fakeApi = FakeAppVersionApi();
    final repository = AppVersionRepository(fakeApi);

    expect(await repository.checkUpdateType(), UpdateType.none);
    fakeApi.updateType = UpdateType.force;
    expect(await repository.checkUpdateType(), UpdateType.force);
  });
}
