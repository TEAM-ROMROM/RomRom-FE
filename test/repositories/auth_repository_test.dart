import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/repositories/auth_repository.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';

/// 인증 API 대역: 재발급 결과 조절, 호출 횟수 기록
class FakeRomAuthApi implements RomAuthApi {
  bool isRefreshSucceeded = true;
  int refreshAccessTokenCallCount = 0;
  int fetchAndSaveMemberInfoCallCount = 0;

  @override
  Future<bool> refreshAccessToken() async {
    refreshAccessTokenCallCount++;
    return isRefreshSucceeded;
  }

  @override
  Future<void> fetchAndSaveMemberInfo() async => fetchAndSaveMemberInfoCallCount++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AuthRepository', () {
    late FakeRomAuthApi fakeApi;
    late AuthRepository repository;

    setUp(() {
      fakeApi = FakeRomAuthApi();
      repository = AuthRepository(fakeApi);
    });

    test('refreshAccessToken은 API 재발급 결과(성공·실패)를 그대로 반환', () async {
      expect(await repository.refreshAccessToken(), isTrue);
      fakeApi.isRefreshSucceeded = false;
      expect(await repository.refreshAccessToken(), isFalse);
      expect(fakeApi.refreshAccessTokenCallCount, 2);
    });

    test('fetchAndSaveMemberInfo는 API에 1회 위임', () async {
      await repository.fetchAndSaveMemberInfo();
      expect(fakeApi.fetchAndSaveMemberInfoCallCount, 1);
    });
  });
}
