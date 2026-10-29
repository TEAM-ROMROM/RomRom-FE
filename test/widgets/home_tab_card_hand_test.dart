import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/widgets/home_tab_card_hand.dart';
import 'package:romrom_fe/widgets/request_management_item_card_widget.dart';
import '../helpers/pump_design_screen.dart';

// 초기 팬 애니메이션 시작 지연(500ms) 이후 시점
const Duration afterFanStartDelay = Duration(milliseconds: 600);

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
