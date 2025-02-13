/// 사용자 정보 싱글톤으로 관리
class UserInfo {
  String? name;
  String? email;
  String? profileImageUrl;

  // Singleton 인스턴스를 저장할 변수
  static final UserInfo _instance = UserInfo._internal();

  // private 생성자
  UserInfo._internal();

  // Singleton 인스턴스를 반환하는 getter
  factory UserInfo() {
    return _instance;
  }

  // 사용자 정보 설정 메서드
  void setUserInfo(String? name, String? email, String? profileImageUrl) {
    this.name = name ?? '';
    this.email = email ?? '';
    this.profileImageUrl = profileImageUrl ?? '';
  }

  // 사용자 정보 반환 메서드
  Map<String, String?> getUserInfo() {
    return {
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
    };
  }
}
