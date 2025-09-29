import 'package:flutter/material.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/services/apis/member_api.dart';

/// 현재 로그인한 회원 정보를 관리 (UserInfo에 위임)
class MemberManagerService {
  static final MemberManagerService _instance = MemberManagerService._internal();
  factory MemberManagerService() => _instance;
  MemberManagerService._internal();

  // UserInfo 인스턴스 사용
  final UserInfo _userInfo = UserInfo();

  // 캐시된 회원 정보
  Member? _cachedMember;

  // 로딩 상태 관리
  bool _isLoading = false;
  bool _isInitialized = false;

  // 리스너들 (상태 변화 감지용)
  final List<VoidCallback> _listeners = [];

  /// 상태 변화 리스너 추가
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// 상태 변화 리스너 제거
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// 리스너들에게 상태 변화 알림
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// 현재 회원 ID 가져오기 (UserInfo에 위임)
  Future<String?> getCurrentMemberId() async {
    return await _userInfo.getCurrentMemberId();
  }

  /// 현재 회원 정보 가져오기 (캐시 우선, 없으면 API 호출)
  Future<Member?> getCurrentMember({bool forceRefresh = false}) async {
    // 이미 로딩 중이면 대기
    if (_isLoading && !forceRefresh) {
      return _cachedMember;
    }

    // 캐시된 데이터가 있고 강제 새로고침이 아니면 캐시 반환
    if (_cachedMember != null && !forceRefresh) {
      return _cachedMember;
    }

    // UserInfo에서 정보를 가져와서 Member 객체 생성
    await _userInfo.getUserInfo();
    if (_userInfo.memberId?.isNotEmpty == true) {
      _cachedMember = Member(
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
      _isInitialized = true;
    }

    return _cachedMember ?? await _fetchMemberInfo();
  }

  /// 서버에서 회원 정보 가져오기
  Future<Member?> _fetchMemberInfo() async {
    if (_isLoading) return _cachedMember;

    _isLoading = true;
    _notifyListeners();

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

        _cachedMember = response.member;
        _isInitialized = true;
      }

      return _cachedMember;
    } catch (e) {
      debugPrint('회원 정보 조회 실패: $e');
      return null;
    } finally {
      _isLoading = false;
      _notifyListeners();
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

    _cachedMember = member;
    _isInitialized = true;
    _notifyListeners();
  }

  /// 두 회원 ID가 같은지 비교하는 헬퍼 메서드 (UserInfo에 위임)
  Future<bool> isSameMember(String? targetMemberId) async {
    return await _userInfo.isSameMember(targetMemberId);
  }

  /// 현재 로그인한 회원이 작성자인지 확인 (UserInfo에 위임)
  Future<bool> isAuthor(String? authorMemberId) async {
    return await _userInfo.isAuthor(authorMemberId);
  }

  /// 로그아웃 시 캐시 및 저장된 정보 삭제 (UserInfo에 위임)
  Future<void> clearMemberInfo() async {
    await _userInfo.clearAllInfo();

    _cachedMember = null;
    _isInitialized = false;
    _notifyListeners();
  }

  /// 현재 로딩 상태
  bool get isLoading => _isLoading;

  /// 초기화 여부
  bool get isInitialized => _isInitialized;

  /// 캐시된 회원 정보 (즉시 접근용)
  Member? get cachedMember => _cachedMember;

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

  /// 두 회원 ID가 동일한지 확인
  static Future<bool> hasSameMemberId(String? targetMemberId) async {
    return await _service.isSameMember(targetMemberId);
  }

  /// 현재 회원이 지정된 회원과 동일한지 확인 (작성자 체크용)
  static Future<bool> isCurrentMember(String? memberId) async {
    return await _service.isSameMember(memberId);
  }

  /// 회원 정보 저장 (로그인 시 호출)
  static Future<void> saveMemberInfo(Member member) async {
    return await _service.saveMemberInfo(member);
  }

  /// 회원 정보 삭제 (로그아웃 시 호출)
  static Future<void> clearMemberInfo() async {
    return await _service.clearMemberInfo();
  }

  /// 즉시 접근 가능한 캐시된 정보
  static Member? get cachedMember => _service.cachedMember;
  static String? get cachedMemberId => _service.cachedMemberId;
  static bool get isLoading => _service.isLoading;
  static bool get isInitialized => _service.isInitialized;

  /// 상태 변화 리스너
  static void addListener(VoidCallback listener) => _service.addListener(listener);
  static void removeListener(VoidCallback listener) => _service.removeListener(listener);
}