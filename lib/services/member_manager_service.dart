import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/utils/single_flight.dart';

/// 현재 로그인한 회원 정보: 저장은 UserInfo(SharedPreferences) 단일 원본, 화면용 회원 상태는 memberProfileProvider
/// 이 서비스는 Member 객체를 따로 캐시하지 않음 (두 곳 캐시 불일치 방지, #975)
class MemberManagerService {
  static final MemberManagerService _instance = MemberManagerService._internal();
  factory MemberManagerService() => _instance;
  MemberManagerService._internal();

  // UserInfo 인스턴스 사용
  final UserInfo _userInfo = UserInfo();

  // 서버 회원 정보 조회 단일 실행 (동시 호출은 같은 결과 공유)
  final SingleFlight<Member?> _memberFetchFlight = SingleFlight<Member?>();

  /// 현재 회원 ID 가져오기 (UserInfo에 위임)
  Future<String?> getCurrentMemberId() async {
    return await _userInfo.getCurrentMemberId();
  }

  /// 현재 회원 정보: 저장된 정보 있으면 UserInfo로 구성, 없거나 강제 새로고침이면 서버 조회
  Future<Member?> getCurrentMember({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      await _userInfo.getUserInfo();
      if (_userInfo.memberId?.isNotEmpty == true) return _toMemberFromUserInfo();
    }
    return _memberFetchFlight.run(_fetchMemberInfo);
  }

  /// UserInfo 저장 값 > Member
  Member _toMemberFromUserInfo() {
    return Member(
      memberId: _userInfo.memberId,
      email: _userInfo.email,
      nickname: _userInfo.nickname,
      profileUrl: _userInfo.profileUrl,
      socialPlatform: _userInfo.socialPlatform,
      role: _userInfo.role,
      accountStatus: _userInfo.accountStatus,
      latitude: _userInfo.latitude,
      longitude: _userInfo.longitude,
      isFirstLogin: _userInfo.isFirstLogin,
      isItemCategorySaved: _userInfo.isItemCategorySaved,
      isFirstItemPosted: _userInfo.isFirstItemPosted,
      isMemberLocationSaved: _userInfo.isMemberLocationSaved,
      isRequiredTermsAgreed: _userInfo.isRequiredTermsAgreed,
      isMarketingInfoAgreed: _userInfo.isMarketingInfoAgreed,
      createdDate: _userInfo.createdDate,
      updatedDate: _userInfo.updatedDate,
    );
  }

  /// 서버에서 회원 정보 가져오기
  Future<Member?> _fetchMemberInfo() async {
    try {
      final memberApi = MemberApi();
      final response = await memberApi.getMemberInfo();

      if (response.member != null) {
        // UserInfo에 저장 (FlutterSecureStorage 대신 SharedPreferences 사용)
        await _userInfo.saveMemberInfo(
          memberId: response.member!.memberId,
          nickname: response.member!.nickname,
          email: response.member!.email,
          profileUrl: response.member!.profileUrl,
          socialPlatform: response.member!.socialPlatform,
          role: response.member!.role,
          accountStatus: response.member!.accountStatus,
          latitude: response.member!.latitude,
          longitude: response.member!.longitude,
          createdDate: response.member!.createdDate,
          updatedDate: response.member!.updatedDate,
        );

        // 온보딩 관련 정보도 업데이트
        if (response.member!.isFirstLogin != null ||
            response.member!.isFirstItemPosted != null ||
            response.member!.isItemCategorySaved != null ||
            response.member!.isMemberLocationSaved != null ||
            response.member!.isRequiredTermsAgreed != null ||
            response.member!.isMarketingInfoAgreed != null) {
          await _userInfo.saveLoginStatus(
            isFirstLogin: response.member!.isFirstLogin ?? false,
            isFirstItemPosted: response.member!.isFirstItemPosted ?? false,
            isItemCategorySaved: response.member!.isItemCategorySaved ?? false,
            isMemberLocationSaved: response.member!.isMemberLocationSaved ?? false,
            isMarketingInfoAgreed: response.member!.isMarketingInfoAgreed ?? false,
            isRequiredTermsAgreed: response.member!.isRequiredTermsAgreed ?? false,
          );
        }
      }

      return response.member;
    } catch (e) {
      debugPrint('회원 정보 조회 실패: $e');
      return null;
    }
  }

  /// 로그인 시 회원 정보 저장 (로그인 플로우에서 호출)
  Future<void> saveMemberInfo(Member member) async {
    // UserInfo에 저장
    await _userInfo.saveMemberInfo(
      memberId: member.memberId,
      nickname: member.nickname,
      email: member.email,
      profileUrl: member.profileUrl,
      socialPlatform: member.socialPlatform,
      role: member.role,
      accountStatus: member.accountStatus,
      latitude: member.latitude,
      longitude: member.longitude,
      createdDate: member.createdDate,
      updatedDate: member.updatedDate,
    );

    // 온보딩 관련 정보도 저장
    await _userInfo.saveLoginStatus(
      isFirstLogin: member.isFirstLogin ?? false,
      isFirstItemPosted: member.isFirstItemPosted ?? false,
      isItemCategorySaved: member.isItemCategorySaved ?? false,
      isMemberLocationSaved: member.isMemberLocationSaved ?? false,
      isMarketingInfoAgreed: member.isMarketingInfoAgreed ?? false,
      isRequiredTermsAgreed: member.isRequiredTermsAgreed ?? false,
    );
  }

  /// 로그아웃 시 캐시 및 저장된 정보 삭제 (UserInfo에 위임)
  Future<void> clearMemberInfo() async {
    await _userInfo.clearUserInfoExceptIsCoachMarkShown();
  }

  /// 캐시된 회원 ID (즉시 접근용)
  String? get cachedMemberId => _userInfo.memberId;
}

/// 회원 정보 관리를 위한 정적 메서드 제공 클래스
/// TokenManager와 동일한 패턴으로 구현
class MemberManager {
  static final MemberManagerService _service = MemberManagerService();

  /// 현재 회원 정보 가져오기
  static Future<Member?> getCurrentMember({bool forceRefresh = false}) async {
    return await _service.getCurrentMember(forceRefresh: forceRefresh);
  }

  /// 현재 회원 ID 가져오기
  static Future<String?> getCurrentMemberId() async {
    return await _service.getCurrentMemberId();
  }

  /// 회원 정보 저장 (로그인 시 호출)
  static Future<void> saveMemberInfo(Member member) async {
    return await _service.saveMemberInfo(member);
  }

  /// 회원 정보 삭제 (로그아웃 시 호출)
  static Future<void> clearMemberInfo() async {
    return await _service.clearMemberInfo();
  }

  /// 즉시 접근 가능한 캐시된 회원 ID
  static String? get cachedMemberId => _service.cachedMemberId;
}
