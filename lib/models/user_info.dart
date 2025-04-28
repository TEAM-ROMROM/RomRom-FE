import 'package:shared_preferences/shared_preferences.dart';

/// 사용자 정보 관리 class
class UserInfo {
  String? nickname;
  String? email;
  String? profileUrl;
  bool? isFirstLogin;
  bool? isFirstItemPosted;
  bool? isItemCategorySaved;
  bool? isMemberLocationSaved;

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

  // 로그인 상태(첫 로그인 여부, 카테고리 선택 여부, 위치 인증 여부) 저장
  Future<void> saveFirstLoginStatus({
    required bool isFirstLogin,
    required bool isFirstItemPosted,
    required bool isItemCategorySaved,
    required bool isMemberLocationSaved,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final Map<String, bool> statusMap = {
      'isFirstLogin': isFirstLogin,
      'isFirstItemPosted': isFirstItemPosted,
      'isItemCategorySaved': isItemCategorySaved,
      'isMemberLocationSaved': isMemberLocationSaved,
    };

    for (final entry in statusMap.entries) {
      await prefs.setBool(entry.key, entry.value);
    }

    this.isFirstLogin = isFirstLogin;
    this.isFirstItemPosted = isFirstItemPosted;
    this.isItemCategorySaved = isItemCategorySaved;
    this.isMemberLocationSaved = isMemberLocationSaved;
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
