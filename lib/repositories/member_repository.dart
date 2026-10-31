// lib/repositories/member_repository.dart
import 'package:romrom_fe/models/apis/responses/member_response.dart';
import 'package:romrom_fe/services/apis/member_api.dart';

class MemberRepository {
  final MemberApi _api;

  MemberRepository(this._api);

  /// 본인 회원 정보 조회
  Future<MemberResponse> getMemberInfo() => _api.getMemberInfo();

  /// 타인 회원 프로필 조회 (차단 여부·위치 문구 포함)
  Future<MemberResponse> getMemberProfile(String memberId) => _api.getMemberProfile(memberId);

  /// 프로필 수정 (닉네임/이미지 URL)
  Future<void> updateProfile({required String nickname, required String profileUrl}) =>
      _api.updateMemberProfile(nickname, profileUrl);

  /// 선호 카테고리 저장 (카테고리 id 목록 > 서버 저장 성공 여부)
  Future<bool> savePreferredCategories(List<int> preferredCategories) =>
      _api.savePreferredCategories(preferredCategories);

  /// 회원 위치 저장 (좌표 + 행정구역)
  Future<void> saveLocation({
    required double longitude,
    required double latitude,
    required String siDo,
    required String siGunGu,
    required String eupMyoenDong,
    String? ri,
  }) => _api.saveMemberLocation(
    longitude: longitude,
    latitude: latitude,
    siDo: siDo,
    siGunGu: siGunGu,
    eupMyoenDong: eupMyoenDong,
    ri: ri,
  );

  /// 탐색 범위 저장 (미터 단위 > 서버 저장 성공 여부)
  Future<bool> saveSearchRadius(double searchRadiusInMeters) => _api.saveSearchRadius(searchRadiusInMeters);

  /// 약관 동의 저장 (마케팅 동의 여부 포함 > 서버 저장 성공 여부)
  Future<bool> saveTermsAgreement({required bool isMarketingInfoAgreed}) =>
      _api.saveTermsAgreement(isMarketingInfoAgreed: isMarketingInfoAgreed);
}
