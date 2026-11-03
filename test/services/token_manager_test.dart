import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/token_keys.dart';
import 'package:romrom_fe/services/token_manager.dart';

/// 테스트용 보안저장소: 메모리 값, 읽기 횟수 기록, 읽기 지연(Completer) 선택
class _FakeSecureStorage extends Fake implements FlutterSecureStorage {
  _FakeSecureStorage([Map<String, String>? initialValues]) : values = {...?initialValues};

  final Map<String, String> values;
  int readCount = 0;
  // 지정 시 읽기가 이 Future 완료까지 대기 (로드 중 저장·삭제 경합 재현)
  Future<void>? readGate;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    readCount++;
    final valueAtReadStart = values[key];
    if (readGate != null) await readGate;
    return valueAtReadStart;
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}

/// 토큰 메모리 캐시 검증: 첫 읽기만 저장소 접근, 동시 첫 읽기 1회, 저장·삭제 즉시 반영, 로드 중 저장 우선
void main() {
  Map<String, String> buildStoredTokens() => {
    TokenKeys.accessToken.name: 'stored-access',
    TokenKeys.refreshToken.name: 'stored-refresh',
  };

  test('첫 읽기에 저장소 1회 로드 (access·refresh 2키) > 이후 읽기는 메모리', () async {
    final storage = _FakeSecureStorage(buildStoredTokens());
    final tokenManager = TokenManager.withStorage(storage);

    expect(await tokenManager.getAccessToken(), 'stored-access');
    expect(await tokenManager.getRefreshToken(), 'stored-refresh');
    expect(await tokenManager.getAccessToken(), 'stored-access');

    expect(storage.readCount, 2);
  });

  test('동시 첫 읽기 여러 건 > 저장소 로드 1회', () async {
    final storage = _FakeSecureStorage(buildStoredTokens());
    final tokenManager = TokenManager.withStorage(storage);

    final tokens = await Future.wait([
      tokenManager.getAccessToken(),
      tokenManager.getRefreshToken(),
      tokenManager.getAccessToken(),
    ]);

    expect(tokens, ['stored-access', 'stored-refresh', 'stored-access']);
    expect(storage.readCount, 2);
  });

  test('저장 > 메모리·저장소 모두 새 토큰', () async {
    final storage = _FakeSecureStorage(buildStoredTokens());
    final tokenManager = TokenManager.withStorage(storage);
    await tokenManager.getAccessToken();

    await tokenManager.saveTokens('new-access', 'new-refresh');

    expect(await tokenManager.getAccessToken(), 'new-access');
    expect(await tokenManager.getRefreshToken(), 'new-refresh');
    expect(storage.values[TokenKeys.accessToken.name], 'new-access');
    expect(storage.values[TokenKeys.refreshToken.name], 'new-refresh');
  });

  test('삭제 > 메모리 null, 저장소 비움, 재로드 없음', () async {
    final storage = _FakeSecureStorage(buildStoredTokens());
    final tokenManager = TokenManager.withStorage(storage);
    await tokenManager.getAccessToken();

    await tokenManager.deleteTokens();

    expect(await tokenManager.getAccessToken(), isNull);
    expect(await tokenManager.getRefreshToken(), isNull);
    expect(storage.values, isEmpty);
    expect(storage.readCount, 2);
  });

  test('저장소 로드 중 저장 > 늦게 끝난 로드가 새 토큰을 덮어쓰지 않음', () async {
    final readGate = Completer<void>();
    final storage = _FakeSecureStorage(buildStoredTokens())..readGate = readGate.future;
    final tokenManager = TokenManager.withStorage(storage);

    final pendingAccessToken = tokenManager.getAccessToken();
    await tokenManager.saveTokens('new-access', 'new-refresh');
    readGate.complete();

    expect(await pendingAccessToken, 'new-access');
    expect(await tokenManager.getRefreshToken(), 'new-refresh');
  });

  test('저장된 토큰 없음 > null, 다시 읽어도 저장소 재접근 없음', () async {
    final storage = _FakeSecureStorage();
    final tokenManager = TokenManager.withStorage(storage);

    expect(await tokenManager.getAccessToken(), isNull);
    expect(await tokenManager.getRefreshToken(), isNull);
    expect(storage.readCount, 2);
  });
}
