import 'package:flutter/material.dart';

class AppColors {
  // 공통
  static const Color primaryBlack = Color(0xFF1D1E27);
  static const Color opacity30PrimaryBlack = Color(0x4D1D1E27); // 30% 불투명도 primaryBlack
  static const Color opacity90PrimaryBlack = Color(0xE61D1E27); // 90% 불투명도 primaryBlack
  static const Color primaryYellow = Color(0xFFFFC300);
  static const Color secondaryBlack1 = Color(0xFF34353D);
  static const Color secondaryBlack2 = Color(0xFF4C4E54);
  static const Color lightGray = Color(0xFFEEEEEE);

  static const Color opacity10White = Color(0x1AFFFFFF); // 10% 불투명도 흰색
  static const Color opacity20White = Color(0x33FFFFFF); // 20% 불투명도 흰색
  static const Color opacity30White = Color(0x4DFFFFFF); // 30% 불투명도 흰색
  static const Color opacity40White = Color(0x66FFFFFF); // 40% 불투명도 흰색
  static const Color opacity50White = Color(0x80FFFFFF); // 50% 불투명도 흰색
  static const Color opacity60White = Color(0x99FFFFFF); // 60% 불투명도 흰색
  static const Color opacity80White = Color(0xCCFFFFFF); // 80% 불투명도 흰색

  static const Color opacity10Black = Color(0x1A000000); // 10% 불투명도 검정
  static const Color opacity15Black = Color(0x26000000); // 15% 불투명도 검정
  static const Color opacity20Black = Color(0x33000000); // 20% 불투명도 검정
  static const Color opacity50Black = Color(0x80000000); // 50% 불투명도 검정
  static const Color opacity70Black = Color(0xB3000000); // 70% 불투명도 검정
  static const Color opacity80Black = Color(0xCC000000); // 80% 불투명도 검정

  static const Color opacity20PrimaryYellow = Color(0x33FFC300);

  // 로그인 화면
  static const Color kakao = Color(0xFFFEE500); // 카카오 배경
  static const Color google = Color(0xFFF3F4F4); // 구글 배경

  // 동네 인증하기 화면
  static const Color locationVerificationAreaLabel = Color(0x4CFFFFFF); // 흰색, opacity 30%
  static const Color currentLocationButtonIcon = Color(0xFF007AFF); // 현재 위치 버튼 아이콘
  static const Color currentLocationButtonBg = Color(0xFFFFFFFF); // 현재 위치 버튼 배경
  static const Color currentLocationButtonShadow = Color(0xFF001B60); // 현재 위치 버튼 그림자
  static const Color currentLocationButtonBorder = Color(0xFFB7B7B7); // 현재 위치 버튼 테두리

  static const Color bottomNavigationDisableIcon = Color(0xFF676767); // 하단 네비게이션바 비활성화 아이콘

  // 물품 카드
  static final Color itemCardBackground = const Color(0xFFFFFFFF).withValues(alpha: 0.8); // 물품 카드 배경 색상
  static final Color itemCardBorder = const Color(0xFFFFFFFF).withValues(alpha: 0.6); // 물품 카드 테두리 색상
  static const Color itemCardShadow = Color(0x26000000); // 물품 카드 그림자 색상 , 검정색, opacity 15%
  static const Color itemCardNameText = Color(0xFF131419); // 물품 카드 텍스트 색상
  static const Color itemCardCategoryText = Color(0x80131419); // 물품 카드 카테고리 텍스트 색상
  static const Color itemCardPriceText = Color(0xFF1D1E27); // 물품 카드 가격 텍스트 색상
  static const Color itemCardLikeText = Color(0x991D1E27); // 물품 카드 좋아요 텍스트 색상
  static const Color itemCardOptionChip = Color(0xFFD2D2D2); // 물품 카드 요청 옵션 칩 색상

  // Item 내부 태그
  static const Color conditionTagBackground = Color(0xFFFFF1C4); // 사용감 태그 (노란색 계열)
  static const Color transactionTagBackground = Color(0xFFCACDFF); // 거래 방식 태그 (보라색)
  static const Color priceTagBackground = Color(0xFFE8E8E8); // 가격 태그 (회색)

  // 이미지 플레이스홀더 배경
  static const Color imagePlaceholderBackground = Color(0xFFD9D9D9); // 연한 회색

  // AI 태그 및 버튼
  static const Color aiTagBackground = Color(0x4DCF7DFF); // 어두운 보라색 배경
  static const Color aiButtonGlow = Color(0xFF7B00FF); // 보라색 광택 효과

  // 온보딩 프로그레스 헤더
  static final Color onboardingProgressInactiveLine = primaryYellow.withValues(alpha: 0.1); // 비활성화 프로그레스 선
  static const Color onboardingProgressStepPendingBg = primaryBlack; // 대기 단계 배경색 (primaryBlack과 동일)
  static final Color onboardingProgressStepPendingBorder = primaryYellow.withValues(alpha: 0.1); // 대기 단계 테두리
  static final Color onboardingProgressStepPendingText = primaryYellow.withValues(alpha: 0.3); // 대기 단계 텍스트

  // 텍스트 색상
  static const Color textColorWhite = Color(0xFFFFFFFF);
  static const Color textColorBlack = Color(0xFF000000);

  // 투명 색상
  static const Color transparent = Color(0x00000000);

  // 아이템 옵션 메뉴
  static const Color itemOptionsMenuRedText = Color(0xFFFF5656); // 삭제 텍스트 색상
  static const Color itemOptionsMenuRedIcon = Color(0xFF993333); // 삭제 아이콘 색상

  // 경고 다이얼로그
  static const Color warningRed = Color(0xFFFF5656); // 경고 아이콘 및 버튼 색상

  // 다이얼로그 배리어 (배경 오버레이)
  static const Color dialogBarrier = Color(0x80000000); // 50% 불투명도 검정 (다이얼로그 배경)

  // toast 배경 색상
  static const Color toastSuccessBackground = Color(0xFF30CF00); // 성공 및 확인 토스트 아이콘 배경색
  static const Color toastErrorBackground = Color(0xFFFF5656); // 오류 토스트 아이콘 배경색
  static const Color toastInfoBackground = Color(0xFF4C4E54); // 정보 토스트 아이콘 배경색

  // 물품 등록 화면
  // 물품 교환 AI 추천 가격 토글 Switch
  static const Color toggleSwitchIndicatorShadow = Color(0x40000000); // 검은색, opacity 25%
  static const Color aiSuggestionContainerBackground = Color(0x4DCF7DFF); // ai 추천 가격 태그 배경색
  // 물품 사진
  static const Color itemPictureRemoveButtonBackground = Color(0xFFD2D2D2); // 물품 사진 삭제 버튼 배경색

  // 물품 상세 화면
  // 물품 사진오버레이 그레디언트
  static List<Color> itemDetailBlackGradient = [
    Colors.black.withValues(alpha: 0.2),
    Colors.black.withValues(alpha: 0.0),
    Colors.black.withValues(alpha: 0.0),
    Colors.black.withValues(alpha: 0.3),
  ];
  // 하단 오버레이 그레디언트
  static List<Color> itemDetailBottomBlackGradient = [
    AppColors.primaryBlack.withValues(alpha: 0.0),
    AppColors.primaryBlack.withValues(alpha: 1.0),
  ];

  // ai 그라데이션
  static const List<Color> aiGradient = [
    Color(0xFF5889F2), // 파란 테두리(Gradient 1)
    Color(0xFF9858F2), // 보라 테두리(Gradient 2)
    Color(0xFFF258F2), // 핑크 테두리(Gradient 3)
    Color(0xFFF25893), // 다홍 테두리(Gradient 4)
  ];

  // 홈 피드 - blackGradient container 그라데이션
  static List<Color> blackGradient1 = [
    Colors.black,
    Colors.black.withValues(alpha: 0.28),
    Colors.white.withValues(alpha: 0.0),
  ];
  static List<Color> blackGradient2 = [
    Colors.black,
    Colors.black.withValues(alpha: 0.0),
    Colors.black.withValues(alpha: 0.0),
    Colors.black.withValues(alpha: 0.3),
  ];

  // 홈 화면 카드 드롭 존
  static const Color cardDropZoneBorder = Colors.white; // 드롭 존 테두리 색상
  static Color cardDropZoneBackground = Colors.white.withValues(alpha: 0.3); // 드롭 존 배경 색상
  static Color cardDropZoneShadow = Colors.white; // 드롭 존 배경 색상

  // 홈 화면 거래 요청 Dialog
  static const Color transactionRequestDialogCancelButton = Color(0xFFDEDACE); // 거래 요청 다이얼로그 테두리 색상

  static const Color errorBorder = Color(0xFFFF5656); // 에러 상태 테두리 색상
  static const Color errorContainer = Color(0x1AFF5656); // 에러 상태 컨테이너 색상

  // 요청 관리 화면
  static const Color tradeStatusIsChatting = Color(0x80FFC300); // 채팅 중 색상
  static const Color tradeStatusIsCompleted = Color(0xFF34353D); // 거래 완료 색상

  // 거래 요청 화면 - 배경 그라데이션
  static const List<Color> tradeRequestBackgroundGradient = [
    AppColors.primaryBlack,
    Colors.black, // 검정
    AppColors.primaryBlack,
  ];

  // 채팅 화면
  static const Color chatLocationTimeMessage = Color(0x99FFFFFF); // 장소, 시간, 메시지 (white e60% opacity)
  static const Color chatUnreadBadge = Color(0xFFFF3E3E); // 읽지 않은 메시지 뱃지
  static const Color chatActiveStatus = Color(0xFF30CF00); // 활성 상태 색상 (초록색)
  static const Color chatInactiveStatus = Color(0xFFFF3E3E); // 비활성 상태 색상 (빨간색)
}
