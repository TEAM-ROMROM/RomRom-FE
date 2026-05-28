// lib/repositories/member_repository.dart
import 'package:romrom_fe/models/apis/responses/member_response.dart';
import 'package:romrom_fe/services/apis/member_api.dart';

class MemberRepository {
  final MemberApi _api;

  MemberRepository(this._api);

  /// 본인 회원 정보 조회
  Future<MemberResponse> getMemberInfo() => _api.getMemberInfo();

  /// 프로필 수정 (닉네임/이미지 URL)
  Future<void> updateProfile({required String nickname, required String profileUrl}) =>
      _api.updateMemberProfile(nickname, profileUrl);
}
