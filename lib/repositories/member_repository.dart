// lib/repositories/member_repository.dart
import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/responses/member_response.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/services/apis/member_api.dart';

class MemberRepository {
  final MemberApi _api;
  // 내 정보 조회 성공 시 로컬 저장 (UserInfo 프로필 동기화, 없으면 저장 안 함)
  final Future<void> Function(Member member)? _saveFetchedMyMember;

  MemberRepository(this._api, {Future<void> Function(Member member)? saveFetchedMyMember})
    : _saveFetchedMyMember = saveFetchedMyMember;

  /// 본인 회원 정보 조회 > 로컬 프로필 동기화 (저장 실패는 조회 결과에 영향 없음)
  Future<MemberResponse> getMemberInfo() async {
    final response = await _api.getMemberInfo();
    final fetchedMember = response.member;
    final saveFetchedMyMember = _saveFetchedMyMember;
    if (fetchedMember != null && saveFetchedMyMember != null) {
      try {
        await saveFetchedMyMember(fetchedMember);
      } catch (error) {
        debugPrint('[member repository] local profile sync failed : $error');
      }
    }
    return response;
  }

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

  /// 탈퇴 전 진행 중 거래 목록 (탈퇴 시 서버가 자동 취소) (#1008)
  Future<List<TradeRequestHistory>> getOngoingTradesBeforeWithdrawal() async {
    final tradeResponse = await _api.getOngoingTradesBeforeWithdrawal();
    return tradeResponse.ongoingTradeRequestHistories;
  }

  /// 탐색 범위 저장 (미터 단위 > 서버 저장 성공 여부)
  Future<bool> saveSearchRadius(double searchRadiusInMeters) => _api.saveSearchRadius(searchRadiusInMeters);

  /// 약관 동의 저장 (마케팅 동의 여부 포함 > 서버 저장 성공 여부)
  Future<bool> saveTermsAgreement({required bool isMarketingInfoAgreed}) =>
      _api.saveTermsAgreement(isMarketingInfoAgreed: isMarketingInfoAgreed);
}
