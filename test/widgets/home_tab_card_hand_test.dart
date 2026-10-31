import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/widgets/home_tab_card_hand.dart';
import 'package:romrom_fe/widgets/request_management_item_card_widget.dart';
import '../helpers/pump_design_screen.dart';

// 초기 팬 애니메이션 시작 지연(500ms) 이후 시점
const Duration afterFanStartDelay = Duration(milliseconds: 600);

// 카드 뽑기 떠오름(200ms) 완료 이후 시점
const Duration pullLiftSettleDuration = Duration(milliseconds: 300);

/// 테스트 카드 목록 (이미지 없음 > 네트워크 미사용 플레이스홀더)
List<Item> buildTestCards(int count) {
  return List.generate(
    count,
    (index) => Item(
      itemId: 'item-$index',
      itemName: '물품 $index',
      itemCategory: 'SHOES',
      price: 1000,
      likeCount: 0,
      isAiPredictedPrice: false,
    ),
  );
}

/// 카드 핸드 렌더 > 팬 애니메이션 종료까지 대기
Future<void> pumpCardHand(WidgetTester tester, {required int cardCount}) async {
  useDesignScreenView(tester);

  await tester.pumpWidget(
    buildDesignScreenApp(
      home: Scaffold(
        body: Stack(
          children: [
            Positioned(left: 0, right: 0, bottom: 0, child: HomeTabCardHand(cards: buildTestCards(cardCount))),
          ],
        ),
      ),
    ),
  );
  await tester.pump(afterFanStartDelay);
  await tester.pumpAndSettle();
}

/// 드롭 안내 아이콘의 위쪽 여백 (아이콘 위아래 움직임 값)
double readDropGuideIconTopPadding(WidgetTester tester) {
  final padding = tester.widget<Padding>(
    find.ancestor(of: find.byIcon(AppIcons.cardDrag), matching: find.byType(Padding)).first,
  );
  return (padding.padding as EdgeInsets).top;
}

/// 카드 위에서 위로 당겨 뽑기 > 떠오름 완료까지 대기 > 위로 60px 더 이동 (손가락은 누른 채 반환)
Future<TestGesture> startCardPull(WidgetTester tester, Finder card) async {
  final gesture = await tester.startGesture(tester.getCenter(card));
  // 수직 판별 8px, 당기기 시작 -15px 초과
  await gesture.moveBy(const Offset(0, -20));
  await tester.pump();
  await gesture.moveBy(const Offset(0, -20));
  await tester.pump();
  await tester.pump(pullLiftSettleDuration);
  await gesture.moveBy(const Offset(0, -60));
  await tester.pump();
  return gesture;
}

/// 화면상 카드 대각선 길이 (회전 무관, 표시 배율 비교용)
double readCardDiagonal(WidgetTester tester, Finder card) {
  return (tester.getBottomRight(card) - tester.getTopLeft(card)).distance;
}

void main() {
  group('HomeTabCardHand 애니메이션 프레임', () {
    testWidgets('초기 상태 > 드롭 안내 아이콘 없음, 예약 프레임 없음(상시 반복 애니메이션 없음)', (tester) async {
      await pumpCardHand(tester, cardCount: 3);

      expect(find.byIcon(AppIcons.cardDrag), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('카드 당기기 > 아이콘 위아래 반복, 놓으면 정지', (tester) async {
      await pumpCardHand(tester, cardCount: 3);

      // 카드 위에서 위로 당기기 (수직 판별 8px, 당기기 시작 -15px 초과)
      final cardCenter = tester.getCenter(find.byType(RequestManagementItemCardWidget).first);
      final gesture = await tester.startGesture(cardCenter);
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();

      // 당긴 상태: 아이콘 표시 + 시간 경과에 따라 위치 변화
      expect(find.byIcon(AppIcons.cardDrag), findsOneWidget);
      final topPaddingAtStart = readDropGuideIconTopPadding(tester);
      await tester.pump(const Duration(milliseconds: 350));
      expect(readDropGuideIconTopPadding(tester), isNot(topPaddingAtStart));
      expect(tester.binding.hasScheduledFrame, isTrue);

      // 놓기 (드롭존 밖) > 원위치 후 프레임 종료
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byIcon(AppIcons.cardDrag), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('HomeTabCardHand 뽑기·spring 복귀', () {
    testWidgets('떠오름 완료 후 드래그 > 카드가 손가락을 1:1로 따라감', (tester) async {
      await pumpCardHand(tester, cardCount: 3);
      final pulledCard = find.byType(RequestManagementItemCardWidget).first;

      final gesture = await startCardPull(tester, pulledCard);
      final Offset centerAfterLift = tester.getCenter(pulledCard);

      // 위로 30px, 오른쪽 25px 이동 > 카드 중심도 같은 만큼 이동 (보간·지연 없음)
      await gesture.moveBy(const Offset(25, -30));
      await tester.pump();
      final Offset fingerFollowDelta = tester.getCenter(pulledCard) - centerAfterLift;
      expect(fingerFollowDelta.dx, closeTo(25, 0.01));
      expect(fingerFollowDelta.dy, closeTo(-30, 0.01));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('놓기(드롭존 밖) > 놓은 자리에서 끊김 없이 출발해 spring으로 원위치 수렴', (tester) async {
      await pumpCardHand(tester, cardCount: 3);
      final pulledCard = find.byType(RequestManagementItemCardWidget).first;
      final Offset restingCenter = tester.getCenter(pulledCard);
      final double restingDiagonal = readCardDiagonal(tester, pulledCard);

      final gesture = await startCardPull(tester, pulledCard);
      final Offset releaseCenter = tester.getCenter(pulledCard);
      final double releaseDistance = (releaseCenter - restingCenter).distance;
      expect(releaseDistance, greaterThan(50));

      // 놓은 직후 첫 프레임: 순간이동 없이 놓은 자리 근처
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final double distanceAfterFirstFrame = (tester.getCenter(pulledCard) - restingCenter).distance;
      expect(distanceAfterFirstFrame, greaterThan(releaseDistance * 0.7));

      // 복귀 중간: 원위치로 단조롭게 다가감 (감쇠비 1.0 > 넘침 없음)
      double previousDistance = distanceAfterFirstFrame;
      for (int frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final double currentDistance = (tester.getCenter(pulledCard) - restingCenter).distance;
        expect(currentDistance, lessThanOrEqualTo(previousDistance + 0.01));
        previousDistance = currentDistance;
      }
      expect(previousDistance, lessThan(releaseDistance));

      // 정착: 원래 자리·원래 크기, 예약 프레임 없음
      await tester.pumpAndSettle();
      expect((tester.getCenter(pulledCard) - restingCenter).distance, lessThan(0.01));
      expect(readCardDiagonal(tester, pulledCard), closeTo(restingDiagonal, 0.01));
      expect(find.byIcon(AppIcons.cardDrag), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('HomeTabCardHand 궤도 회전', () {
    testWidgets('좌우 드래그 > 카드 위치 이동', (tester) async {
      await pumpCardHand(tester, cardCount: 7);

      final firstCard = find.byType(RequestManagementItemCardWidget).first;
      final positionBeforeDrag = tester.getCenter(firstCard);

      // 가운데 카드 위에서 수평 드래그 (수평 판별 > 회전 전용, 카드 밖 빈 영역은 제스처 미수신)
      final gesture = await tester.startGesture(tester.getCenter(find.byType(RequestManagementItemCardWidget).at(3)));
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();

      expect(tester.getCenter(firstCard), isNot(positionBeforeDrag));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('왼쪽으로 충분히 회전 > 오른쪽 카드 추가 로드', (tester) async {
      await pumpCardHand(tester, cardCount: 10);
      expect(find.byType(RequestManagementItemCardWidget), findsNWidgets(7));

      // 회전각 변화 0.2 초과 필요 (감도 0.0045 > 약 45px 이상)
      final gesture = await tester.startGesture(tester.getCenter(find.byType(RequestManagementItemCardWidget).at(3)));
      for (int step = 0; step < 6; step++) {
        await gesture.moveBy(const Offset(-20, 0));
        await tester.pump();
      }

      expect(find.byType(RequestManagementItemCardWidget), findsNWidgets(10));

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
