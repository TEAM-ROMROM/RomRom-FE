import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/widgets/home_tab_card_hand/card_hand_geometry.dart';
import 'package:romrom_fe/widgets/home_tab_card_hand/card_hand_layout.dart';

// 기준값: 분리 전 home_tab_card_hand.dart 수식으로 계산한 값 (393 화면, 궤도 -90도 기준)
const double designScreenWidth = 393;
const double valueTolerance = 1e-9;
const double baseOrbitAngle = -math.pi / 2;

final CardHandLayout designLayout = CardHandLayout.fromScreenWidth(designScreenWidth);

/// 카드 정적 위치 계산 (디자인 화면 기준)
CardHandCardTransform calculateDesignTransform(int index, int totalCards, {double orbitAngle = baseOrbitAngle}) {
  return CardHandGeometry.calculateCardTransform(
    layout: designLayout,
    screenWidth: designScreenWidth,
    index: index,
    totalCards: totalCards,
    orbitAngle: orbitAngle,
  );
}

/// 카드 렌더 자세 계산 (기본값: 팬 완료·재정렬 없음·상호작용 없음)
CardHandCardPose calculateDesignPose({
  required int index,
  int totalCards = 7,
  double fanProgress = 1.0,
  CardHandCardTransform? preReorderTransform,
  double reorderProgress = 0.0,
  bool isGatheringReorder = false,
  bool isPulled = false,
  bool isHovered = false,
  bool isPressed = false,
  double pullProgress = 0.0,
  Offset pullOffset = Offset.zero,
  bool isAiHighlighted = false,
  double highlightFloatOffsetPixels = 0.0,
}) {
  return CardHandGeometry.calculateCardPose(
    layout: designLayout,
    screenWidth: designScreenWidth,
    transform: calculateDesignTransform(index, totalCards),
    index: index,
    fanProgress: fanProgress,
    preReorderTransform: preReorderTransform,
    reorderProgress: reorderProgress,
    isGatheringReorder: isGatheringReorder,
    isPulled: isPulled,
    isHovered: isHovered,
    isPressed: isPressed,
    pullProgress: pullProgress,
    pullOffset: pullOffset,
    isAiHighlighted: isAiHighlighted,
    highlightFloatOffsetPixels: highlightFloatOffsetPixels,
  );
}

/// 자세 값 비교 (left, top, angle, scale)
void expectPose(CardHandCardPose pose, List<double> expectedLeftTopAngleScale) {
  expect(pose.left, closeTo(expectedLeftTopAngleScale[0], valueTolerance));
  expect(pose.top, closeTo(expectedLeftTopAngleScale[1], valueTolerance));
  expect(pose.angle, closeTo(expectedLeftTopAngleScale[2], valueTolerance));
  expect(pose.scale, closeTo(expectedLeftTopAngleScale[3], valueTolerance));
}

void main() {
  group('CardHandLayout', () {
    test('디자인 화면(393) > 기본 크기 그대로', () {
      expect(designLayout.cardWidth, 92);
      expect(designLayout.cardHeight, 137);
      expect(designLayout.pullLift, 80);
      expect(designLayout.baseBottom, 50);
      expect(designLayout.deckRadius, 340);
      expect(designLayout.deckCenterYOffset, 140);
    });

    test('iPad(820) > 393 기준 비율로 확대', () {
      final tabletLayout = CardHandLayout.fromScreenWidth(820);
      expect(tabletLayout.cardWidth, closeTo(92 * 820 / 393, valueTolerance));
      expect(tabletLayout.deckRadius, closeTo(340 * 820 / 393, valueTolerance));
    });

    test('궤도 각도 상수 > 10도 간격, 최대 기울기 8도', () {
      expect(CardHandLayout.deckStepAngle, closeTo(10 * math.pi / 180, valueTolerance));
      expect(CardHandLayout.deckMaxTilt, closeTo(8 * math.pi / 180, valueTolerance));
      expect(CardHandLayout.deckDepth, 8);
    });
  });

  group('CardHandGeometry.calculateCardTransform', () {
    test('7장 중 맨 왼쪽 카드', () {
      final transform = calculateDesignTransform(0, 7);
      expect(transform.left, closeTo(-19.499999999999943, valueTolerance));
      expect(transform.top, closeTo(95.55136271329081, valueTolerance));
      expect(transform.angle, closeTo(-0.5235987290562009, valueTolerance));
      expect(transform.centerX, closeTo(26.500000000000057, valueTolerance));
      expect(transform.zIndex, 4);
    });

    test('7장 중 가운데 카드 > 화면 중앙, 최대 tilt', () {
      final transform = calculateDesignTransform(3, 7);
      expect(transform.left, closeTo(150.50000000000003, valueTolerance));
      expect(transform.top, closeTo(50.0, valueTolerance));
      expect(transform.angle, closeTo(0.13962634015954636, valueTolerance));
      expect(transform.centerX, closeTo(196.50000000000003, valueTolerance));
      expect(transform.zIndex, 15);
    });

    test('7장 중 맨 오른쪽 카드', () {
      final transform = calculateDesignTransform(6, 7);
      expect(transform.left, closeTo(320.5, valueTolerance));
      expect(transform.top, closeTo(95.55136271329081, valueTolerance));
      expect(transform.angle, closeTo(0.5235988221403965, valueTolerance));
      expect(transform.zIndex, 10);
    });

    test('카드 1장 > tilt 0', () {
      final transform = calculateDesignTransform(0, 1);
      expect(transform.left, closeTo(150.50000000000003, valueTolerance));
      expect(transform.angle, 0.0);
      expect(transform.zIndex, 9);
    });

    test('궤도 회전(+0.1) > 가운데 카드 오른쪽 이동', () {
      final transform = calculateDesignTransform(2, 5, orbitAngle: baseOrbitAngle + 0.1);
      expect(transform.left, closeTo(184.44336165992164, valueTolerance));
      expect(transform.top, closeTo(51.69858380547123, valueTolerance));
      expect(transform.angle, closeTo(0.23962634015954645, valueTolerance));
      expect(transform.centerX, closeTo(230.44336165992164, valueTolerance));
      expect(transform.zIndex, 13);
    });
  });

  group('CardHandGeometry.isPositionInsideCard', () {
    test('카드 중심 > hit, 카드 밖 빈 영역 > miss', () {
      final transform = calculateDesignTransform(3, 7);
      final cardCenter = Offset(transform.centerX, transform.top + designLayout.cardHeight / 2);
      expect(
        CardHandGeometry.isPositionInsideCard(position: cardCenter, transform: transform, layout: designLayout),
        isTrue,
      );
      expect(
        CardHandGeometry.isPositionInsideCard(
          position: const Offset(196, 260),
          transform: transform,
          layout: designLayout,
        ),
        isFalse,
      );
    });

    test('회전 반영 > 회전 전 사각형 모서리는 miss, 회전된 모서리 안쪽은 hit', () {
      // 맨 오른쪽 카드 (약 30도 회전)
      final transform = calculateDesignTransform(6, 7);
      final cardCenter = Offset(transform.centerX, transform.top + designLayout.cardHeight / 2);
      final halfWidth = designLayout.cardWidth / 2;
      final halfHeight = designLayout.cardHeight / 2;
      final unrotatedTopLeftCorner = cardCenter + Offset(-halfWidth + 2, -halfHeight + 2);
      expect(
        CardHandGeometry.isPositionInsideCard(
          position: unrotatedTopLeftCorner,
          transform: transform,
          layout: designLayout,
        ),
        isFalse,
      );
      // 카드 로컬 (0, -halfHeight + 2) > rotateZ(angle) 적용 위치
      final localPoint = Offset(0, -halfHeight + 2);
      final rotatedPoint = Offset(
        localPoint.dx * math.cos(transform.angle) - localPoint.dy * math.sin(transform.angle),
        localPoint.dx * math.sin(transform.angle) + localPoint.dy * math.cos(transform.angle),
      );
      expect(
        CardHandGeometry.isPositionInsideCard(
          position: cardCenter + rotatedPoint,
          transform: transform,
          layout: designLayout,
        ),
        isTrue,
      );
    });
  });

  group('CardHandGeometry 궤도 각도', () {
    test('7장 > 최소·최대 각도', () {
      expect(CardHandGeometry.calculateMinOrbitAngle(7), closeTo(-2.0943951023931953, valueTolerance));
      expect(CardHandGeometry.calculateMaxOrbitAngle(7), closeTo(-1.0471975511965979, valueTolerance));
    });

    test('1장 이하 > 기본 각도(-90도)', () {
      expect(CardHandGeometry.calculateMinOrbitAngle(1), baseOrbitAngle);
      expect(CardHandGeometry.calculateMaxOrbitAngle(0), baseOrbitAngle);
    });

    test('AI 추천 궤도 각도 > 첫 카드 왼쪽 끝 배치 (최소·최대 제한 포함)', () {
      double calculateHighlightOrbit(int totalCards) => CardHandGeometry.calculateHighlightOrbitAngle(
        layout: designLayout,
        screenWidth: designScreenWidth,
        totalCards: totalCards,
        cardLeftMarginPixels: 8,
      );
      expect(calculateHighlightOrbit(7), closeTo(-1.4796708258379545, valueTolerance));
      expect(calculateHighlightOrbit(10), closeTo(-1.217871438038805, valueTolerance));
      // 2장 > 최소 각도로 제한
      expect(calculateHighlightOrbit(2), closeTo(-1.658062789394613, valueTolerance));
      expect(calculateHighlightOrbit(0), baseOrbitAngle);
    });
  });

  group('CardHandGeometry.calculateCardPose', () {
    test('팬 진행 50% > 스태거 반영 보간', () {
      expectPose(calculateDesignPose(index: 2, fanProgress: 0.5), [
        124.52223262102723,
        58.71276014937369,
        -0.035837420481442554,
        1.0,
      ]);
    });

    test('재정렬(추천 2개 이상) > 집결·홀드·팬아웃 단계', () {
      final preReorderTransform = calculateDesignTransform(5, 7);
      CardHandCardPose calculateGatherPose(double reorderProgress) => calculateDesignPose(
        index: 1,
        preReorderTransform: preReorderTransform,
        reorderProgress: reorderProgress,
        isGatheringReorder: true,
        isAiHighlighted: true,
        highlightFloatOffsetPixels: -10,
      );
      expectPose(calculateGatherPose(0.2), [229.99296299952067, 57.655426028275215, 0.2704351527045046, 1.0]);
      expectPose(calculateGatherPose(0.45), [150.5, 51.5, 0.0, 1.0]);
      expectPose(calculateGatherPose(0.8), [61.89980987001489, 58.360631379906266, -0.23049603769985774, 1.0]);
    });

    test('재정렬(추천 1개) > 직선 이동', () {
      expectPose(
        calculateDesignPose(index: 1, preReorderTransform: calculateDesignTransform(5, 7), reorderProgress: 0.5),
        [152.24430273096092, 70.36944129879927, -0.2934479948047567, 1.0],
      );
    });

    test('hover > 1.12배, float 미적용 / press > 1.05배', () {
      expectPose(
        calculateDesignPose(index: 3, isHovered: true, isAiHighlighted: true, highlightFloatOffsetPixels: -10),
        [150.50000000000003, 51.035, 0.1270599695451872, 1.12],
      );
      expectPose(calculateDesignPose(index: 3, isPressed: true), [
        150.50000000000003,
        51.035,
        0.1270599695451872,
        1.05,
      ]);
    });

    test('당김 50% > 변위·상승·확대·회전 감소, float 미적용', () {
      expectPose(
        calculateDesignPose(
          index: 3,
          isPulled: true,
          pullProgress: 0.5,
          pullOffset: const Offset(12, -40),
          isAiHighlighted: true,
          highlightFloatOffsetPixels: -10,
        ),
        [156.50000000000003, -8.965000000000003, 0.0635299847725936, 1.25],
      );
    });

    test('AI 추천 카드 > float 오프셋 적용', () {
      final restingPose = calculateDesignPose(index: 3);
      final floatingPose = calculateDesignPose(index: 3, isAiHighlighted: true, highlightFloatOffsetPixels: -10);
      expect(floatingPose.top, closeTo(restingPose.top - 10, valueTolerance));
    });
  });

  group('CardHandGeometry 드롭존', () {
    test('당긴 카드 좌상단 > 정적 위치 + 변위 - 상승 높이', () {
      final topLeft = CardHandGeometry.calculatePulledCardTopLeft(
        layout: designLayout,
        transform: calculateDesignTransform(3, 7),
        pullOffset: const Offset(12, -40),
        pullProgress: 0.5,
      );
      expect(topLeft.dx, closeTo(156.50000000000003, valueTolerance));
      expect(topLeft.dy, closeTo(-10.0, valueTolerance));
    });

    test('그림자 강도 > 이전 70% + 목표 30%', () {
      expect(
        CardHandGeometry.calculateNextDropShadowStrength(currentStrength: 0.0, isOverDropZone: true),
        closeTo(0.3, 1e-12),
      );
      expect(
        CardHandGeometry.calculateNextDropShadowStrength(currentStrength: 1.0, isOverDropZone: false),
        closeTo(0.7, 1e-12),
      );
      expect(
        CardHandGeometry.calculateNextDropShadowStrength(currentStrength: 1.0, isOverDropZone: true),
        closeTo(1.0, 1e-12),
      );
    });
  });
}
