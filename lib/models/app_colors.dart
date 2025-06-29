import 'package:flutter/material.dart';

class AppColors {
  // 공통
  static const Color primaryBlack = Color(0xFF1D1E27);
  static const Color primaryYellow = Color(0xFFFFC300);
  static const Color opacity20White = Color(0x33FFFFFF); // 20% 불투명도 흰색
  static const Color opacity30White = Color(0x4DFFFFFF); // 30% 불투명도 흰색
  static const Color opacity50White = Color(0x80FFFFFF); // 50% 불투명도 흰색
  static const Color opacity80White = Color(0xCCFFFFFF); // 80% 불투명도 흰색
  static const Color opacity10Black = Color(0x1A000000); // 10% 불투명도 검정
  static const Color opacity70Black = Color(0xB3000000); // 70% 불투명도 검정

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

  // 물품 카드
  static final Color itemCardBackground =
      const Color(0xFFFFFFFF).withValues(alpha: 0.8); // 물품 카드 배경 색상
  static final Color itemCardBorder =
      const Color(0xFFFFFFFF).withValues(alpha: 0.6); // 물품 카드 테두리 색상
  static const Color itemCardShadow =
      Color(0x26000000); // 물품 카드 그림자 색상 , 검정색, opacity 15%
  static const Color itemCardText = Color(0xFF131419); // 물품 카드 텍스트 색상
  static const Color itemCardOptionChip = Color(0xFFD2D2D2); // 물품 카드 요청 옵션 칩 색상

  // Item 내부 태그
  static const Color conditionTagBackground =
      Color(0xFFFFF1C4); // 사용감 태그 (노란색 계열)
  static const Color transactionTagBackground =
      Color(0xFFCACDFF); // 거래 방식 태그 (보라색)
  static const Color priceTagBackground = Color(0xFFE8E8E8); // 가격 태그 (회색)

  // AI 태그 및 버튼
  static const Color aiTagBackground = Color(0xFF121A1A); // 어두운 배경
  static const Color aiTagGradientBorder1 =
      Color(0xFF5889F2); // 파란 테두리(Gradient 1)
  static const Color aiTagGradientBorder2 =
      Color(0xFF9858F2); // 보라 테두리(Gradient 2)
  static const Color aiTagGradientBorder3 =
      Color(0xFFF258F2); // 핑크 테두리(Gradient 3)
  static const Color aiTagGradientBorder4 =
      Color(0xFFF25893); // 다홍 테두리(Gradient 4)
  static const Color aiButtonGlow = Color(0xFF7B00FF); // 보라색 광택 효과

  // 온보딩 프로그레스 헤더
  static final Color onboardingProgressInactiveLine =
      primaryYellow.withValues(alpha: 0.1); // 비활성화 프로그레스 선
  static const Color onboardingProgressStepPendingBg =
      Color(0xFF1D1E27); // 대기 단계 배경색 (primaryBlack과 동일)
  static final Color onboardingProgressStepPendingBorder =
      primaryYellow.withValues(alpha: 0.1); // 대기 단계 테두리
  static final Color onboardingProgressStepPendingText =
      primaryYellow.withValues(alpha: 0.3); // 대기 단계 텍스트

  // 텍스트 색상
  static const Color textColorWhite = Color(0xFFFFFFFF);
  static const Color textColorBlack = Color(0xFF000000);
}
