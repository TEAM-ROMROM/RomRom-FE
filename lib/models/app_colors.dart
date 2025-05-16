import 'package:flutter/material.dart';

class AppColors {
  // 공통
  static const Color primaryBlack = Color(0xFF131419);
  static const Color primaryYellow = Color(0xFFFFC300);

  // 로그인 화면
  static const Color kakao = Color(0xFFFEE500); // 카카오 배경
  static const Color google = Color(0xFFF3F4F4); // 구글 배경

  // 동네 인증하기 화면
  static const Color locationVerificationAreaLabel =
      Color(0x4CFFFFFF); // 흰색, opacity 30%
  static const Color currentLocationButtonIcon =
      Color(0xFF007AFF); // 현재 위치 버튼 아이콘
  static const Color currentLocationButtonBg = Color(0xFFFFFFFF); // 현재 위치 버튼 배경
  static const Color currentLocationButtonShadow =
      Color(0xFF001B60); // 현재 위치 버튼 그림자
  static const Color currentLocationButtonBorder =
      Color(0xFFB7B7B7); // 현재 위치 버튼 테두리

  static const Color bottomNavigationDisableIcon =
      Color(0xFF676767); // 하단 네비게이션바 비활성화 아이콘

  // 텍스트 색상
  static const Color textColorWhite = Color(0xFFFFFFFF);
  static const Color textColorBlack = Color(0xFF000000);
}
