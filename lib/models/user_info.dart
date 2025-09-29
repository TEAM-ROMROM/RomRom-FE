import 'package:shared_preferences/shared_preferences.dart';

/// 통합 사용자 정보 관리 클래스
/// SharedPreferences를 사용하여 Member 정보와 온보딩 상태를 단일 저장소에서 관리
class UserInfo {
  // === 기본 사용자 정보 ===
  String? memberId;
  String? nickname;
  String? email;
  String? profileUrl;
  String? socialPlatform;
  String? role;
  String? accountStatus;

  // === 온보딩 및 상태 정보 ===
  bool? isFirstLogin;
  bool? isFirstItemPosted;
  bool? isItemCategorySaved;
  bool? isMemberLocationSaved;
  bool? isMarketingInfoAgreed;
  bool? isRequiredTermsAgreed;

  // === 위치 및 메타 정보 ===
  double? latitude;
  double? longitude;
  DateTime? createdDate;
  DateTime? updatedDate;

  // === 싱글톤 구현 ===
  static final UserInfo _instance = UserInfo._internal();
  factory UserInfo() => _instance;
  UserInfo._internal();

  // === 데이터 저장 메서드들 ===

  /// Member 정보 저장 (API 응답 데이터 저장용)
  Future<void> saveMemberInfo({
    String? memberId,
    String? nickname,
    String? email,
    String? profileUrl,
    String? socialPlatform,
    String? role,
    String? accountStatus,
    double? latitude,
    double? longitude,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Member 관련 정보 저장
    await prefs.setString('memberId', memberId ?? '');
    await prefs.setString('nickname', nickname ?? '');
    await prefs.setString('email', email ?? '');
    await prefs.setString('profileUrl', profileUrl ?? '');
    await prefs.setString('socialPlatform', socialPlatform ?? '');
    await prefs.setString('role', role ?? '');
    await prefs.setString('accountStatus', accountStatus ?? '');
    await prefs.setDouble('latitude', latitude ?? 0.0);
    await prefs.setDouble('longitude', longitude ?? 0.0);

    if (createdDate != null) {
      await prefs.setString('createdDate', createdDate.toIso8601String());
    }
    if (updatedDate != null) {
      await prefs.setString('updatedDate', updatedDate.toIso8601String());
    }

    // 메모리에 캐시
    this.memberId = memberId;
    this.nickname = nickname;
    this.email = email;
    this.profileUrl = profileUrl;
    this.socialPlatform = socialPlatform;
    this.role = role;
    this.accountStatus = accountStatus;
    this.latitude = latitude;
    this.longitude = longitude;
    this.createdDate = createdDate;
    this.updatedDate = updatedDate;
  }

  /// 기본 사용자 정보 저장 (소셜 로그인용)
  Future<void> saveUserInfo(
      String? name, String? email, String? profileImageUrl) async {
    await saveMemberInfo(
      nickname: name,
      email: email,
      profileUrl: profileImageUrl,
    );
  }

  /// 온보딩 및 약관 동의 상태 저장
  Future<void> saveLoginStatus({
    required bool isFirstLogin,
    required bool isFirstItemPosted,
    required bool isItemCategorySaved,
    required bool isMemberLocationSaved,
    required bool isMarketingInfoAgreed,
    required bool isRequiredTermsAgreed,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final Map<String, bool> statusMap = {
      'isFirstLogin': isFirstLogin,
      'isFirstItemPosted': isFirstItemPosted,
      'isItemCategorySaved': isItemCategorySaved,
      'isMemberLocationSaved': isMemberLocationSaved,
      'isMarketingInfoAgreed': isMarketingInfoAgreed,
      'isRequiredTermsAgreed': isRequiredTermsAgreed,
    };

    for (final entry in statusMap.entries) {
      await prefs.setBool(entry.key, entry.value);
    }

    this.isFirstLogin = isFirstLogin;
    this.isFirstItemPosted = isFirstItemPosted;
    this.isItemCategorySaved = isItemCategorySaved;
    this.isMemberLocationSaved = isMemberLocationSaved;
    this.isMarketingInfoAgreed = isMarketingInfoAgreed;
    this.isRequiredTermsAgreed = isRequiredTermsAgreed;
  }

  // === 데이터 로드 메서드 ===

  /// 저장된 모든 사용자 정보 로드
  Future<void> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();

    // 기본 정보
    memberId = prefs.getString('memberId') ?? '';
    nickname = prefs.getString('nickname') ?? '';
    email = prefs.getString('email') ?? '';
    profileUrl = prefs.getString('profileUrl') ?? '';
    socialPlatform = prefs.getString('socialPlatform') ?? '';
    role = prefs.getString('role') ?? '';
    accountStatus = prefs.getString('accountStatus') ?? '';

    // 위치 정보
    latitude = prefs.getDouble('latitude');
    longitude = prefs.getDouble('longitude');

    // 날짜 정보
    final createdDateStr = prefs.getString('createdDate');
    final updatedDateStr = prefs.getString('updatedDate');

    if (createdDateStr != null && createdDateStr.isNotEmpty) {
      try {
        createdDate = DateTime.parse(createdDateStr);
      } catch (e) {
        createdDate = null;
      }
    }

    if (updatedDateStr != null && updatedDateStr.isNotEmpty) {
      try {
        updatedDate = DateTime.parse(updatedDateStr);
      } catch (e) {
        updatedDate = null;
      }
    }

    // 온보딩 및 상태 정보
    isFirstLogin = prefs.getBool('isFirstLogin');
    isFirstItemPosted = prefs.getBool('isFirstItemPosted');
    isItemCategorySaved = prefs.getBool('isItemCategorySaved');
    isMemberLocationSaved = prefs.getBool('isMemberLocationSaved');
    isMarketingInfoAgreed = prefs.getBool('isMarketingInfoAgreed');
    isRequiredTermsAgreed = prefs.getBool('isRequiredTermsAgreed');
  }

  // === 온보딩 관련 로직 ===

  /// 온보딩이 필요한지 확인
  bool get needsOnboarding {
    return isRequiredTermsAgreed != true ||
           isMemberLocationSaved != true ||
           isItemCategorySaved != true;
  }

  /// 다음 온보딩 단계 결정
  int get nextOnboardingStep {
    if (isRequiredTermsAgreed != true) return 1;  // 이용약관 동의
    if (isMemberLocationSaved != true) return 2;  // 위치 인증
    if (isItemCategorySaved != true) return 3;    // 카테고리 선택
    return 1; // 기본값
  }

  // === 회원 식별 및 비교 메서드들 ===

  /// 현재 회원 ID 가져오기
  Future<String?> getCurrentMemberId() async {
    if (memberId != null && memberId!.isNotEmpty) {
      return memberId;
    }
    await getUserInfo();
    return memberId?.isNotEmpty == true ? memberId : null;
  }

  /// 두 멤버 ID가 같은지 비교하는 헬퍼 메서드
  Future<bool> isSameMember(String? targetMemberId) async {
    if (targetMemberId == null || targetMemberId.isEmpty) {
      return false;
    }

    final currentMemberId = await getCurrentMemberId();
    return currentMemberId != null && currentMemberId == targetMemberId;
  }

  /// 현재 로그인한 회원이 작성자인지 확인
  Future<bool> isAuthor(String? authorMemberId) async {
    return await isSameMember(authorMemberId);
  }

  // === 데이터 삭제 메서드 ===

  /// 로그아웃 시 모든 정보 삭제
  Future<void> clearAllInfo() async {
    final prefs = await SharedPreferences.getInstance();

    // 모든 키 삭제
    final keysToRemove = [
      'memberId', 'nickname', 'email', 'profileUrl', 'socialPlatform',
      'role', 'accountStatus', 'latitude', 'longitude', 'createdDate', 'updatedDate',
      'isFirstLogin', 'isFirstItemPosted', 'isItemCategorySaved',
      'isMemberLocationSaved', 'isMarketingInfoAgreed', 'isRequiredTermsAgreed'
    ];

    for (final key in keysToRemove) {
      await prefs.remove(key);
    }

    // 메모리 캐시도 초기화
    memberId = null;
    nickname = null;
    email = null;
    profileUrl = null;
    socialPlatform = null;
    role = null;
    accountStatus = null;
    latitude = null;
    longitude = null;
    createdDate = null;
    updatedDate = null;
    isFirstLogin = null;
    isFirstItemPosted = null;
    isItemCategorySaved = null;
    isMemberLocationSaved = null;
    isMarketingInfoAgreed = null;
    isRequiredTermsAgreed = null;
  }

}
