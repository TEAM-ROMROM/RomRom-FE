// 홈 카드 덱 변환 계산 (순수 함수): 궤도 위치·회전, 히트테스트, 궤도 각도 제한, 애니메이션 자세, 드롭존 판정 값
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:romrom_fe/widgets/home_tab_card_hand/card_hand_layout.dart';

/// 궤도 위 카드 한 장의 정적 목표 위치 (Positioned 기준 left/top, 회전각, 중심 X, zIndex)
@immutable
class CardHandCardTransform {
  final double left;
  final double top;

  // 회전각 = tangent + tilt
  final double angle;
  final double centerX;
  final int zIndex;

  const CardHandCardTransform({
    required this.left,
    required this.top,
    required this.angle,
    required this.centerX,
    required this.zIndex,
  });
}

/// 애니메이션 반영 후 카드 한 장의 렌더 자세 (Positioned left/top, rotateZ 각도, scale)
@immutable
class CardHandCardPose {
  final double left;
  final double top;
  final double angle;
  final double scale;

  const CardHandCardPose({required this.left, required this.top, required this.angle, required this.scale});
}

class CardHandGeometry {
  CardHandGeometry._();

  // 궤도 기본 각도 (화면 위쪽 정중앙, -90도)
  static const double baseOrbitAngle = -math.pi / 2;

  /// 카드 위치 및 회전 계산: 인덱스·궤도 각도 > 원호 위 좌표 > 세로 보정 > tangent + tilt
  static CardHandCardTransform calculateCardTransform({
    required CardHandLayout layout,
    required double screenWidth,
    required int index,
    required int totalCards,
    required double orbitAngle,
  }) {
    final double midIndex = (totalCards - 1) / 2;
    final double relativeIndex = index - midIndex;
    final double angle = (relativeIndex * CardHandLayout.deckStepAngle) + orbitAngle;

    final double centerX = screenWidth / 2;
    final double centerY = layout.deckRadius + layout.deckCenterYOffset;

    final double cardCenterX = centerX + layout.deckRadius * math.cos(angle);
    final double cardCenterY = centerY + layout.deckRadius * math.sin(angle);

    final double verticalShift = layout.deckCenterYOffset - (layout.baseBottom + (layout.cardHeight / 2));
    final double adjustedTop = cardCenterY - verticalShift - (layout.cardHeight / 2);

    final double tangent = angle + math.pi / 2;
    final double proximity = 1.0 - (relativeIndex.abs() / (midIndex + 1e-6));
    // 카드가 1개일 때는 tilt를 0으로 설정
    final double tilt = totalCards == 1 ? 0 : CardHandLayout.deckMaxTilt * proximity;
    final int zIndex = ((CardHandLayout.deckDepth * proximity) + (totalCards + relativeIndex)).round();

    return CardHandCardTransform(
      left: cardCenterX - (layout.cardWidth / 2),
      top: adjustedTop,
      angle: tangent + tilt,
      centerX: cardCenterX,
      zIndex: zIndex,
    );
  }

  /// 터치점이 회전된 카드 사각형 안인지: 카드 중심 기준 상대 좌표 > -angle 역회전 > 사각형 판정
  static bool isPositionInsideCard({
    required Offset position,
    required CardHandCardTransform transform,
    required CardHandLayout layout,
  }) {
    final double cardCenterX = transform.centerX;
    // transform.top은 Positioned.top과 동일 기준점(adjustedTop)이므로 중심 Y는 +height/2
    final double cardCenterY = transform.top + layout.cardHeight / 2;
    // 렌더와 동일한 회전각(tangent + tilt)
    final double angle = transform.angle;

    // 터치점을 카드 중심 기준 상대 좌표로
    final double dx = position.dx - cardCenterX;
    final double dy = position.dy - cardCenterY;

    // 렌더는 rotateZ(angle)이므로 -angle로 역회전해 카드 로컬 좌표로 변환
    final double rotationCosine = math.cos(-angle);
    final double rotationSine = math.sin(-angle);
    final double localX = dx * rotationCosine - dy * rotationSine;
    final double localY = dx * rotationSine + dy * rotationCosine;

    // 역회전된 좌표가 카드 사각형 안이면 이 카드가 hit (회전·세로 위치 반영)
    return localX.abs() < layout.cardWidth / 2 && localY.abs() < layout.cardHeight / 2;
  }

  /// 궤도 최소 각도: 맨 오른쪽 카드가 오른쪽 끝에 올 때 (카드 1장 이하 > 기본 각도)
  static double calculateMinOrbitAngle(int totalCards) {
    if (totalCards <= 1) return baseOrbitAngle;
    final midIndex = (totalCards - 1) / 2;
    return -math.pi / 2 - (midIndex * CardHandLayout.deckStepAngle);
  }

  /// 궤도 최대 각도: 맨 왼쪽 카드가 왼쪽 끝에 올 때 (카드 1장 이하 > 기본 각도)
  static double calculateMaxOrbitAngle(int totalCards) {
    if (totalCards <= 1) return baseOrbitAngle;
    final midIndex = (totalCards - 1) / 2;
    return -math.pi / 2 + (midIndex * CardHandLayout.deckStepAngle);
  }

  /// 재정렬 후 첫 번째 카드(index 0)가 화면 왼쪽 끝에 보이도록 orbit 각도를 역산 (min~max 제한)
  static double calculateHighlightOrbitAngle({
    required CardHandLayout layout,
    required double screenWidth,
    required int totalCards,
    required double cardLeftMarginPixels,
  }) {
    if (totalCards <= 0) return baseOrbitAngle;
    final double centerX = screenWidth / 2;
    // index 0 카드 중앙을 화면 왼쪽에서 cardWidth/2 + 왼쪽 여백 위치에 배치
    final double targetCardCenterX = layout.cardWidth / 2 + cardLeftMarginPixels;
    final double dx = targetCardCenterX - centerX; // 음수 (왼쪽)
    // cos(cardAngle) = dx / deckRadius, 왼쪽(음수)이므로 -acos 사용
    final double cardAngle0 = -math.acos((dx / layout.deckRadius).clamp(-1.0, 1.0));
    final double midIndex = (totalCards - 1) / 2;
    final double orbitAngle = cardAngle0 + midIndex * CardHandLayout.deckStepAngle;
    return orbitAngle.clamp(calculateMinOrbitAngle(totalCards), calculateMaxOrbitAngle(totalCards));
  }

  /// 카드 렌더 자세: 팬(스태거) 보간 > 재정렬 보간 > hover/press 확대 > 당김 효과 > AI 하이라이트 float
  static CardHandCardPose calculateCardPose({
    required CardHandLayout layout,
    required double screenWidth,
    required CardHandCardTransform transform,
    required int index,
    required double fanProgress,
    required CardHandCardTransform? preReorderTransform,
    required double reorderProgress,
    required bool isGatheringReorder,
    required bool isPulled,
    required bool isHovered,
    required bool isPressed,
    required double pullProgress,
    required Offset pullOffset,
    required bool isAiHighlighted,
    required double highlightFloatOffsetPixels,
  }) {
    // 스태거드 애니메이션 효과
    final staggerDelay = index * 0.03;
    final staggeredFanValue = (fanProgress - staggerDelay).clamp(0.0, 1.0);

    final double fanOriginLeft = screenWidth / 2 - layout.cardWidth / 2;
    final double fanOriginTop = layout.deckCenterYOffset - (layout.cardHeight / 2) - (layout.baseBottom * 0.2);

    double left = lerpDouble(fanOriginLeft, transform.left, staggeredFanValue)!;
    double top = lerpDouble(fanOriginTop, transform.top, staggeredFanValue)!;
    double angle = lerpDouble(0.0, transform.angle, staggeredFanValue)!;

    // ── 재정렬 보간 적용 ─────────────────────────────────────────
    // 추천 카드 2개 이상: 전체 카드가 중앙 집결(0→0.4) → 겹쳐서 홀드(0.4→0.6) → 팬아웃(0.6→1.0)
    // 추천 카드 1개: 직선 이동 (집결 애니메이션 생략)
    if (preReorderTransform != null) {
      final oldLeft = preReorderTransform.left;
      final oldTop = preReorderTransform.top;
      final oldAngle = preReorderTransform.angle;
      final t = reorderProgress;

      if (isGatheringReorder) {
        // 집결 기준점: 팬 애니메이션 시작점 (화면 중앙 하단)
        final gatherX = fanOriginLeft;
        final gatherY = fanOriginTop;
        if (t <= 0.4) {
          // 1단계: 현재 위치 → 중앙 집결 (easeIn, 빠르게 빨려듦)
          final gatherT = Curves.easeIn.transform(t / 0.4);
          left = lerpDouble(oldLeft, gatherX, gatherT)!;
          top = lerpDouble(oldTop, gatherY, gatherT)!;
          angle = lerpDouble(oldAngle, 0.0, gatherT)!; // 중앙으로 모일 때 1자 정렬
        } else if (t <= 0.5) {
          // 2단계: 한 점에 완전히 겹쳐서 홀드
          left = gatherX;
          top = gatherY;
          angle = 0.0; // 1자 정렬 유지
        } else {
          // 3단계: 중앙 → 최종 위치 팬아웃 (easeOut, 부드럽게 착지)
          final expandT = Curves.easeOut.transform((t - 0.5) / 0.5);
          left = lerpDouble(gatherX, left, expandT)!;
          top = lerpDouble(gatherY, top, expandT)!;
          angle = lerpDouble(0.0, angle, expandT)!; // 팬아웃 시 최종 각도로 복귀
        }
      } else {
        // 추천 카드 1개: 직선 이동
        left = lerpDouble(oldLeft, left, t)!;
        top = lerpDouble(oldTop, top, t)!;
      }
    }
    // ────────────────────────────────────────────────────────────

    double scale = 1.0;

    if (!isPulled) {
      if (isHovered) {
        scale = math.max(scale, 1.12);
      } else if (isPressed) {
        scale = math.max(scale, 1.05);
      }
    }

    // 카드 뽑기 효과
    if (isPulled) {
      left += pullOffset.dx * pullProgress;
      top += pullOffset.dy * pullProgress - layout.pullLift * pullProgress;
      const double dragBaseScale = 1.15;
      const double dragScaleGain = 0.20;
      scale = dragBaseScale + (dragScaleGain * pullProgress);
      angle *= (1 - pullProgress);
    }

    // ── AI 하이라이트 float 적용 ─────────────────────────────────
    // pulled/hovered 상태에서는 적용하지 않아 기존 드래그 인터랙션과 충돌 없음
    // highlightFloatOffsetPixels: 0.0 → -10.h (위로 슥 한 번만 올라옴, easeOut)
    if (isAiHighlighted && !isPulled && !isHovered) {
      top += highlightFloatOffsetPixels;
    }
    // ────────────────────────────────────────────────────────────

    return CardHandCardPose(left: left, top: top, angle: angle, scale: scale);
  }

  /// 당긴 카드의 덱 로컬 좌상단 (정적 위치 + 당김 변위 - 상승 높이, pull 진행도 반영)
  static Offset calculatePulledCardTopLeft({
    required CardHandLayout layout,
    required CardHandCardTransform transform,
    required Offset pullOffset,
    required double pullProgress,
  }) {
    final cardLeft = transform.left + pullOffset.dx * pullProgress;
    final cardTop = transform.top + pullOffset.dy * pullProgress - layout.pullLift * pullProgress;
    return Offset(cardLeft, cardTop);
  }

  /// 드롭존 그림자 강도 스무딩 (이전 70% + 목표 30%, 0~1 제한)
  static double calculateNextDropShadowStrength({required double currentStrength, required bool isOverDropZone}) {
    final target = isOverDropZone ? 1.0 : 0.0;
    final newT = (currentStrength * 0.7) + (target * 0.3); // 부드럽게
    return newT.clamp(0.0, 1.0);
  }
}
