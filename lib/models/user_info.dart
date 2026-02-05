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
  bool? isCoachMarkShown;

  // === 위치 및 메타 정보 ===
  double? latitude;
  double? longitude;
  DateTime? createdDate;
  DateTime? updatedDate;

  // === 싱글톤 구현 ===
  static final UserInfo _instance = UserInfo._internal();
  factory UserInfo() => _instance;
  UserInfo._internal();

  // === 헬퍼/상수 ===
  /// named parameter가 "전달되지 않음"을 나타내는 sentinel
  static const Object _unset = Object();

  /// 값이 있으면 저장, null이면 키 제거 (String)
  static Future<void> _setOrRemove(SharedPreferences prefs, String key, String? value) async {
    if (value != null && value.isNotEmpty) {
      await prefs.setString(key, value);
    } else {
      await prefs.remove(key);
    }
  }

  /// 값이 있으면 저장, null이면 키 제거 (double)
  static Future<void> _setOrRemoveDouble(SharedPreferences prefs, String key, double? value) async {
    if (value != null) {
      await prefs.setDouble(key, value);
    } else {
      await prefs.remove(key);
    }
  }

  // === 데이터 저장 메서드들 ===

  /// Member 정보 저장 (API 응답 데이터 저장용)
  Future<void> saveMemberInfo({
    Object? memberId = _unset,
    Object? nickname = _unset,
    Object? email = _unset,
    Object? profileUrl = _unset,
    Object? socialPlatform = _unset,
    Object? role = _unset,
    Object? accountStatus = _unset,
    Object? latitude = _unset,
    Object? longitude = _unset,
    Object? createdDate = _unset,
    Object? updatedDate = _unset,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Member 관련 ㄴ정보 저장 (전달된 필드만 반영)
    if (!identical(memberId, _unset)) {
      await _setOrRemove(prefs, 'memberId', memberId as String?);
      this.memberId = memberId;
    }
    if (!identical(nickname, _unset)) {
      await _setOrRemove(prefs, 'nickname', nickname as String?);
      this.nickname = nickname;
    }
    if (!identical(email, _unset)) {
      await _setOrRemove(prefs, 'email', email as String?);
      this.email = email;
    }
    if (!identical(profileUrl, _unset)) {
      await _setOrRemove(prefs, 'profileUrl', profileUrl as String?);
      this.profileUrl = profileUrl;
    }
    if (!identical(socialPlatform, _unset)) {
      await _setOrRemove(prefs, 'socialPlatform', socialPlatform as String?);
      this.socialPlatform = socialPlatform;
    }
    if (!identical(role, _unset)) {
      await _setOrRemove(prefs, 'role', role as String?);
      this.role = role;
    }
    if (!identical(accountStatus, _unset)) {
      await _setOrRemove(prefs, 'accountStatus', accountStatus as String?);
      this.accountStatus = accountStatus;
    }
    if (!identical(latitude, _unset)) {
      await _setOrRemoveDouble(prefs, 'latitude', latitude as double?);
      this.latitude = latitude;
    }
    if (!identical(longitude, _unset)) {
      await _setOrRemoveDouble(prefs, 'longitude', longitude as double?);
      this.longitude = longitude;
    }
    if (!identical(createdDate, _unset)) {
      final DateTime? cd = createdDate as DateTime?;
      if (cd != null) {
        await prefs.setString('createdDate', cd.toIso8601String());
      } else {
        await prefs.remove('createdDate');
      }
      this.createdDate = cd;
    }
    if (!identical(updatedDate, _unset)) {
      final DateTime? ud = updatedDate as DateTime?;
      if (ud != null) {
        await prefs.setString('updatedDate', ud.toIso8601String());
      } else {
        await prefs.remove('updatedDate');
      }
      this.updatedDate = ud;
    }
  }

  /// 기본 사용자 정보 저장 (소셜 로그인용)
  Future<void> saveUserInfo(String? name, String? email, String? profileImageUrl) async {
    await saveMemberInfo(nickname: name, email: email, profileUrl: profileImageUrl);
  }

  /// 온보딩 및 약관 동의 상태 저장
  Future<void> saveLoginStatus({
    required bool isFirstLogin,
    required bool isFirstItemPosted,
    required bool isItemCategorySaved,
    required bool isMemberLocationSaved,
    required bool isMarketingInfoAgreed,
    required bool isRequiredTermsAgreed,
    bool? isCoachMarkShown,
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

    // isCoachMarkShown은 선택적 저장
    if (isCoachMarkShown != null) {
      await prefs.setBool('isCoachMarkShown', isCoachMarkShown);
      this.isCoachMarkShown = isCoachMarkShown;
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

    // 기본 정보 (키가 없으면 null 반환)
    memberId = prefs.getString('memberId');
    nickname = prefs.getString('nickname');
    email = prefs.getString('email');
    profileUrl = prefs.getString('profileUrl');
    socialPlatform = prefs.getString('socialPlatform');
    role = prefs.getString('role');
    accountStatus = prefs.getString('accountStatus');

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
    isCoachMarkShown = prefs.getBool('isCoachMarkShown');
  }

  // === 온보딩 관련 로직 ===

  /// 온보딩이 필요한지 확인
  bool get needsOnboarding {
    return isRequiredTermsAgreed != true || isMemberLocationSaved != true || isItemCategorySaved != true;
  }

  /// 다음 온보딩 단계 결정
  int get nextOnboardingStep {
    if (isRequiredTermsAgreed != true) return 1; // 이용약관 동의
    if (isMemberLocationSaved != true) return 2; // 위치 인증
    if (isItemCategorySaved != true) return 3; // 카테고리 선택
    return 1; // 기본값
  }

  // === 회원 식별 및 비교 메서드들 ===

  /// 현재 회원 ID 가져오기
  Future<String?> getCurrentMemberId() async {
    if (memberId != null) {
      return memberId;
    }
    await getUserInfo();
    return memberId;
  }

  /// 두 멤버 ID가 같은지 비교하는 헬퍼 메서드
  Future<bool> isSameMember(String? targetMemberId) async {
    if (targetMemberId == null) {
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

  /// 로그아웃 시 정보 삭제 (isCoachMarkShown 제외)
  Future<void> clearUserInfoExceptIsCoachMarkShown() async {
    final prefs = await SharedPreferences.getInstance();

    // 로그아웃 시 삭제할 키 목록 (isCoachMarkShown 제외)
    final keysToRemove = [
      'memberId',
      'nickname',
      'email',
      'profileUrl',
      'socialPlatform',
      'role',
      'accountStatus',
      'latitude',
      'longitude',
      'createdDate',
      'updatedDate',
      'isFirstLogin',
      'isFirstItemPosted',
      'isItemCategorySaved',
      'isMemberLocationSaved',
      'isMarketingInfoAgreed',
      'isRequiredTermsAgreed',
      // 'isCoachMarkShown' - 디바이스에 영구 저장
    ];

    for (final key in keysToRemove) {
      await prefs.remove(key);
    }

    // 메모리 캐시도 초기화 (isCoachMarkShown 제외)
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
    // isCoachMarkShown은 유지 (다음 로그인 시 계속 사용)
  }
}
