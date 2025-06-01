import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:playing_cards_layouts/playing_cards_layouts.dart';
import 'package:romrom_fe/widgets/item_card.dart';

/// 부채꼴 모양 카드
class FanCardDial extends StatefulWidget {
  const FanCardDial({super.key});

  @override
  State<FanCardDial> createState() => _FanCardDialState();
}

class _FanCardDialState extends State<FanCardDial> {
  List<Map<String, dynamic>> rawCards = [];
  double angleOffset = 0.0;
  bool deckRaised = false;
  String? raisedCardId;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      generateCards();
    });
  }

  void generateCards() {
    List<Map<String, dynamic>> cards = [];
    for (int i = 0; i < 6; i++) {
      String id = UniqueKey().toString();
      cards.add({
        "color": Colors.primaries[i % Colors.primaries.length],
        "id": id,
        "width": 85.0,
        "height": 135.0,
      });
    }
    setState(() {
      rawCards = cards;
    });
  }

  /// 팬 카드 위젯 리스트를 생성합니다.
  ///
  /// - `fanSpacing`: 카드 간의 간격을 조절합니다.
  /// - `fanRadius`: 카드가 펼쳐질 반지름입니다.
  /// - `cardDisplayWidth`: 각 카드의 가로 길이입니다.
  /// - `baseXOffset`, `baseYOffset`: 카드가 그려질 기준 위치입니다.
  /// - `rotationCenter`: 회전의 기준이 되는 중심 좌표입니다.
  /// - `cardGap`: 카드 간의 추가 간격입니다.
  ///
  /// `fanCards` 함수를 통해 각 카드의 위치와 정보를 계산하고,
  /// `_buildFanCard`를 통해 각각의 카드 위젯을 생성합니다.
  ///
  /// 반환된 리스트는 카드가 겹치지 않도록 역순으로 정렬되어 있습니다.
  List<Widget> buildFanCardWidgets() {
    const double fanSpacing = 0.69;
    const double fanRadius = 200.0;
    const double cardDisplayWidth = 80.0;
    const double baseXOffset = 210.0;
    const double baseYOffset = 260.0;
    const double rotationCenter = 200.0;
    const double cardGap = 10.0;

    /// `positionedCards` 리스트를 생성하여, 카드들을 팬 형태로 배치할 위치와 속성을 계산합니다.
    ///
    /// - `fanCards` 함수는 카드의 배치 방향, 간격, 반지름, 카드의 너비 등의 옵션을 받아 각 카드의 위치 정보를 반환합니다.
    /// - `midIndex`는 카드 리스트의 중앙 인덱스를 계산하여, 팬의 중심을 기준으로 회전 및 위치 계산에 사용됩니다.
    /// - 각 카드에 대해 `_buildFanCard`를 호출하여 위젯을 생성하고, 리스트를 역순으로 반환합니다.

    /// 각 카드를 팬 형태로 배치하기 위한 위젯을 생성합니다.
    ///
    /// - `entry`: 카드의 인덱스와 데이터가 담긴 MapEntry.
    /// - `midIndex`: 카드 리스트의 중앙 인덱스.
    /// - `baseXOffset`, `baseYOffset`: 카드 배치의 기준이 되는 x, y 오프셋.
    /// - `rotationCenter`: 카드 회전의 중심점.
    /// - `cardGap`: 카드 간의 간격.
    List<Map<String, dynamic>> positionedCards = fanCards(rawCards, {
      "flow": "horizontal",
      "fanDirection": "n",
      "spacing": fanSpacing,
      "radius": fanRadius,
      "width": cardDisplayWidth,
    });

    int midIndex = (positionedCards.length - 1) ~/ 2;

    return positionedCards
        .asMap()
        .entries
        .map((entry) => _buildFanCard(
            entry, midIndex, baseXOffset, baseYOffset, rotationCenter, cardGap))
        .toList()
        .reversed
        .toList();
  }

  /// 주어진 카드 정보를 기반으로 팬 카드 UI를 생성합니다.
  ///
  /// [entry]는 카드의 인덱스와 카드 정보를 포함하는 MapEntry입니다.
  /// [midIndex]는 카드 더미의 중앙 인덱스입니다.
  /// [baseXOffset], [baseYOffset]는 카드의 기본 x, y 오프셋입니다.
  /// [rotationCenter]는 회전의 기준점입니다.
  /// [cardGap]은 카드 간의 간격입니다.
  ///
  /// 카드가 선택되거나 덱이 들어올려진 상태에 따라 위치와 애니메이션이 달라집니다.
  /// 카드 클릭 시 덱이 들어올려지거나, 특정 카드가 강조됩니다.
  ///
  /// 반환값은 애니메이션과 회전 효과가 적용된 카드 위젯입니다.
  Widget _buildFanCard(
      MapEntry<int, Map<String, dynamic>> entry,
      int midIndex,
      double baseXOffset,
      double baseYOffset,
      double rotationCenter,
      double cardGap) {
    int index = entry.key;
    var card = entry.value;
    String id = card["card"]?["id"] ?? "unknown";

    double cardAngleRadians = _calculateCardAngleRadians(index, midIndex);

    Offset rotatedPosition = _calculateRotatedPosition(
      card,
      index,
      midIndex,
      baseXOffset,
      baseYOffset,
      rotationCenter,
      cardGap,
    );

    double baseY = rotatedPosition.dy;
    if (deckRaised) baseY -= 30;
    if (raisedCardId == id) baseY -= 20;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.linear,
      left: rotatedPosition.dx,
      top: baseY,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (!deckRaised) {
              deckRaised = true;
            } else {
              raisedCardId = id;
            }
          });
        },
        child: Transform.rotate(
          angle: cardAngleRadians,
          child: MyCustomCard(
            color: card["card"]["color"],
            label: 'Card ${id.substring(0, 4)}',
          ),
        ),
      ),
    );
  }

  /// 카드의 인덱스와 중앙 인덱스를 받아 해당 카드의 각도를 라디안 단위로 계산합니다.
  ///
  /// [index]는 현재 카드의 인덱스이고, [midIndex]는 중앙 카드의 인덱스입니다.
  /// 각 카드는 중앙을 기준으로 10도씩 회전하며, 최종 각도는 angleOffset이 추가된 라디안 값으로 반환됩니다.
  double _calculateCardAngleRadians(int index, int midIndex) {
    double cardAngleDegrees = (index - midIndex) * 10;
    return cardAngleDegrees * pi / 180 + angleOffset;
  }

  /// 카드의 회전된 위치를 계산합니다.
  ///
  /// [card]는 카드의 정보가 담긴 맵입니다.
  /// [index]는 카드의 인덱스입니다.
  /// [midIndex]는 카드 배열의 중앙 인덱스입니다.
  /// [baseXOffset]는 기준 X 오프셋입니다.
  /// [baseYOffset]는 기준 Y 오프셋입니다.
  /// [rotationCenter]는 회전의 중심 좌표입니다.
  /// [cardGap]는 카드 간의 간격입니다.
  ///
  /// 회전 각도(angleOffset)를 기준으로 카드의 새로운 위치(Offset)를 반환합니다.
  Offset _calculateRotatedPosition(
    Map<String, dynamic> card,
    int index,
    int midIndex,
    double baseXOffset,
    double baseYOffset,
    double rotationCenter,
    double cardGap,
  ) {
    double x = (card["coords"]?["x"] ?? 0).toDouble();
    double y = (card["coords"]?["y"] ?? 0).toDouble();
    double extraGap = cardGap;
    double rotatedX = baseXOffset +
        (x - rotationCenter + (index - midIndex) * extraGap) *
            cos(angleOffset) -
        (y - rotationCenter) * sin(angleOffset);
    double rotatedY = baseYOffset +
        (x - rotationCenter) * sin(angleOffset) +
        (y - rotationCenter) * cos(angleOffset);
    return Offset(rotatedX, rotatedY);
  }

  void resetDeck() {
    setState(() {
      deckRaised = false;
      raisedCardId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200.h,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: resetDeck,
        onHorizontalDragUpdate: (details) {
          setState(() {
            angleOffset += details.delta.dx * 0.002;
            angleOffset = angleOffset.clamp(-pi / 4, pi / 4);
          });
        },
        child: Stack(
          children: [
            Positioned(
              bottom: -100,
              left: 0,
              right: 0,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 300,
                child: Stack(
                  children: buildFanCardWidgets(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyCustomCard extends StatelessWidget {
  final Color color;
  final String label;

  const MyCustomCard({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 85.w,
      child: const ItemCard(
        itemCategoryLabel: '스포츠/레저',
        itemName: '윌슨 블레이드 V9',
        itemId: 'demoCard1',
      ),
    );
  }
}
