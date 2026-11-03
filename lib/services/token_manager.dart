import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:romrom_fe/enums/token_keys.dart';

/// 인증 토큰 보관: 보안저장소 영구 저장 + 메모리 캐시 (API 요청마다 보안저장소 읽기 방지)
/// 첫 읽기에 access·refresh 1회 로드 (동시 읽기 공유) > 이후 메모리, 저장·삭제는 메모리 먼저 갱신 후 저장소 반영
class TokenManager {
  // 싱글톤 구현
  static final TokenManager _instance = TokenManager._internal(const FlutterSecureStorage());
  factory TokenManager() => _instance;
  TokenManager._internal(this._storage);

  /// 테스트용: 별도 저장소를 쓰는 독립 인스턴스
  @visibleForTesting
  TokenManager.withStorage(FlutterSecureStorage storage) : _storage = storage;

  final FlutterSecureStorage _storage;

  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  bool _hasLoadedTokens = false;
  Future<void>? _loadingTokens;
  // 저장·삭제마다 증가 > 그보다 먼저 시작한 저장소 로드 결과는 버림
  int _tokenGeneration = 0;

  /// 토큰 저장
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _updateCachedTokens(accessToken: accessToken, refreshToken: refreshToken);
    await _storage.write(key: TokenKeys.accessToken.name, value: accessToken);
    await _storage.write(key: TokenKeys.refreshToken.name, value: refreshToken);
  }

  /// 액세스 토큰 불러오기
  Future<String?> getAccessToken() async {
    await _ensureTokensLoaded();
    return _cachedAccessToken;
  }

  /// 리프레시 토큰 불러오기
  Future<String?> getRefreshToken() async {
    await _ensureTokensLoaded();
    return _cachedRefreshToken;
  }

  /// 토큰 삭제
  Future<void> deleteTokens() async {
    _updateCachedTokens(accessToken: null, refreshToken: null);
    await _storage.delete(key: TokenKeys.accessToken.name);
    await _storage.delete(key: TokenKeys.refreshToken.name);
  }

  /// 메모리 토큰 교체 (저장소 로드 완료 취급)
  void _updateCachedTokens({required String? accessToken, required String? refreshToken}) {
    _tokenGeneration++;
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
    _hasLoadedTokens = true;
  }

  /// 메모리 미적재 시 저장소 로드 1회 (진행 중 로드 공유, 실패 시 다음 읽기에서 재시도)
  Future<void> _ensureTokensLoaded() {
    if (_hasLoadedTokens) return Future<void>.value();
    return _loadingTokens ??= _loadTokensFromStorage().whenComplete(() => _loadingTokens = null);
  }

  /// 저장소 access·refresh 병렬 읽기 > 로드 중 저장·삭제 없었을 때만 메모리 반영
  Future<void> _loadTokensFromStorage() async {
    final generationAtLoadStart = _tokenGeneration;
    final storedTokens = await Future.wait([
      _storage.read(key: TokenKeys.accessToken.name),
      _storage.read(key: TokenKeys.refreshToken.name),
    ]);
    if (generationAtLoadStart != _tokenGeneration) return;
    _updateCachedTokens(accessToken: storedTokens[0], refreshToken: storedTokens[1]);
  }
}
