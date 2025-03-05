import 'package:shared_preferences/shared_preferences.dart';

/// 사용자 정보 관리 class
class UserInfo {
  String? nickname;
  String? email;
  String? profileUrl;
  bool? isFirstLogin;

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

  /// 첫 번째 로그인인지 저장
  Future<void> saveIsFirstLogin(bool isFirst) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLogin', isFirst);
    isFirstLogin = isFirst;
  }

  /// 사용자 정보 불러옴
  Future<void> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    nickname = prefs.getString('nickname') ?? '';
    email = prefs.getString('email') ?? '';
    profileUrl = prefs.getString('profileUrl') ?? '';
    isFirstLogin = prefs.getBool('isFirstLogin');
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
