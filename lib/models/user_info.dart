import 'dart:math';

import 'package:romrom_fe/models/platforms.dart';

/// 사용자 정보 싱글톤으로 관리
class UserInfo {
  String? nickname;
  String? email;
  String? profileUrl;
  Platforms? loginPlatform;

  // Singleton 인스턴스를 저장할 변수
  static final UserInfo _instance = UserInfo._internal();

  // private 생성자
  UserInfo._internal();

  // Singleton 인스턴스를 반환하는 getter
  factory UserInfo() {
    return _instance;
  }

  // 사용자 정보 설정 메서드
  void setUserInfo(String? name, String? email, String? profileImageUrl,
      Platforms loginPlatform) {
    nickname = name ?? '';
    this.email = email ?? '';
    profileUrl = profileImageUrl ?? '';
    this.loginPlatform = loginPlatform;
  }

  // 사용자 정보 반환 메서드
  Map<String, String?> getUserInfo() {
    return {
      'name': nickname,
      'email': email,
      'profileImageUrl': profileUrl,
    };
  }

  // 로그인 플랫폼 반환 메서드
  Platforms getLoginPlatform() {
    return loginPlatform!;
  }
}
