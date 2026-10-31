import 'package:romrom_fe/services/apis/rom_auth_api.dart';

/// 인증 저장소: 토큰 재발급(자동 로그인), 로그인 후 회원 정보 저장 (RomAuthApi 래핑, UI 모름)
class AuthRepository {
  final RomAuthApi _api;

  AuthRepository(this._api);

  /// refresh 토큰으로 access 토큰 재발급 > 성공 여부 (성공 시 로그인 상태·회원 정보 갱신)
  Future<bool> refreshAccessToken() => _api.refreshAccessToken();

  /// 서버 회원 정보 조회 > 로컬 회원 정보 저장 (실패는 내부에서 로그만)
  Future<void> fetchAndSaveMemberInfo() => _api.fetchAndSaveMemberInfo();
}
