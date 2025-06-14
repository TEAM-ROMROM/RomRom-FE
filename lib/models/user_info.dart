import 'package:shared_preferences/shared_preferences.dart';

/// 사용자 정보 관리
class UserInfo {
  String? nickname;
  String? email;
  String? profileUrl;
  bool? isFirstLogin;
  bool? isFirstItemPosted;
  bool? isItemCategorySaved;
  bool? isMemberLocationSaved;
  bool? isMarketingInfoAgreed;    // 마케팅 정보 수신 동의 여부
  bool? isRequiredTermsAgreed;    // 필수 이용약관 동의 여부

  static final UserInfo _instance = UserInfo._internal();
  factory UserInfo() => _instance;
  UserInfo._internal();

  /// 사용자 정보 저장 함수
  Future<void> saveUserInfo(
      String? name, String? email, String? profileImageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', name ?? '');
    await prefs.setString('email', email ?? '');
    await prefs.setString('profileUrl', profileImageUrl ?? '');

    nickname = name;
    this.email = email;
    profileUrl = profileImageUrl;
  }

  /// 로그인 상태 저장 (업데이트된 필드 포함)
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

  /// 사용자 정보 불러옴
  Future<void> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    nickname = prefs.getString('nickname') ?? '';
    email = prefs.getString('email') ?? '';
    profileUrl = prefs.getString('profileUrl') ?? '';
    isFirstLogin = prefs.getBool('isFirstLogin');
    isFirstItemPosted = prefs.getBool('isFirstItemPosted');
    isItemCategorySaved = prefs.getBool('isItemCategorySaved');
    isMemberLocationSaved = prefs.getBool('isMemberLocationSaved');
    isMarketingInfoAgreed = prefs.getBool('isMarketingInfoAgreed');
    isRequiredTermsAgreed = prefs.getBool('isRequiredTermsAgreed');
  }

  /// 온보딩이 필요한지 확인
  bool get needsOnboarding {
    return isFirstLogin == true || 
           isRequiredTermsAgreed != true ||
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

  /// 사용자 정보를 Map 형태로 반환하는 함수
  Map<String, String?> toMap() {
    return {
      'email': email,
      'nickname': nickname,
      'profileUrl': profileUrl,
    };
  }
}
