// 홈 카드 덱 레이아웃 값: 카드 크기·당김 높이·궤도 반지름 (화면 너비 393 기준 비율)
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

@immutable
class CardHandLayout {
  // 디자인 기준 화면 너비 (iPhone 393)
  static const double designScreenWidth = 393.0;

  // 궤도상 카드 간 각도 간격 (10도, 라디안)
  static const double deckStepAngle = 10 * math.pi / 180;

  // 가운데 카드 최대 기울기 (8도, 라디안)
  static const double deckMaxTilt = 8 * math.pi / 180;

  // 가운데 카드 zIndex 가중치
  static const int deckDepth = 8;

  // 초기화 전 기본값 (디자인 기준 화면 크기 그대로)
  static const CardHandLayout designDefault = CardHandLayout(
    cardWidth: 92,
    cardHeight: 137,
    pullLift: 80,
    baseBottom: 50,
    deckRadius: 340,
    deckCenterYOffset: 140,
  );

  final double cardWidth;
  final double cardHeight;

  // 카드 뽑을 때 상승 높이
  final double pullLift;

  // 기본 bottom 위치 (네비게이션 바 위)
  final double baseBottom;
  final double deckRadius;
  final double deckCenterYOffset;

  const CardHandLayout({
    required this.cardWidth,
    required this.cardHeight,
    required this.pullLift,
    required this.baseBottom,
    required this.deckRadius,
    required this.deckCenterYOffset,
  });

  /// 화면 너비 > 카드·궤도 크기 (iPhone 393 기준 비율 유지)
  factory CardHandLayout.fromScreenWidth(double screenWidth) {
    final scale = screenWidth / designScreenWidth;
    return CardHandLayout(
      cardWidth: 92 * scale,
      cardHeight: 137 * scale,
      pullLift: 80 * scale,
      baseBottom: 50 * scale,
      deckRadius: 340 * scale,
      deckCenterYOffset: 140 * scale,
    );
  }
}
