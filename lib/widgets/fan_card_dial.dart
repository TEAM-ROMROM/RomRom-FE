import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:playing_cards_layouts/playing_cards_layouts.dart';

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

  List<Widget> buildFanCardWidgets() {
    // 클래스 상단에 상수 정의
    const double fanSpacing = 0.69;
    const double fanRadius = 200.0;
    const double cardDisplayWidth = 80.0;

    const double baseXOffset = 210.0; // 화면 중앙 X 오프셋
    const double baseYOffset = 260.0; // 화면 하단 Y 오프셋
    const double rotationCenter = 200.0; // 회전 중심점
    const double cardGap = 10.0; // 카드 간 추가 간격

// buildFanCardWidgets 메서드에서 사용
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
        .map((entry) {
          int index = entry.key;
          var card = entry.value;
          String id = card["card"]["id"];

          double cardAngleDegrees = (index - midIndex) * 10;
          double cardAngleRadians = cardAngleDegrees * pi / 180 + angleOffset;

          double x = (card["coords"]?["x"] ?? 0).toDouble();
          double y = (card["coords"]?["y"] ?? 0).toDouble();

// 카드 위치 계산
          double extraGap = cardGap;
          double rotatedX = baseXOffset +
              (x - rotationCenter + (index - midIndex) * extraGap) *
                  cos(angleOffset) -
              (y - rotationCenter) * sin(angleOffset);
          double rotatedY = baseYOffset +
              (x - rotationCenter) * sin(angleOffset) +
              (y - rotationCenter) * cos(angleOffset);

          double baseY = rotatedY;

          if (deckRaised) baseY -= 30;
          if (raisedCardId == id) baseY -= 20;

          double? angle = card["coords"]["angle"];
          if (angle != null) {
            // 패키지 기본 각도 + 드래그로 움직인 angleOffset 적용
            angle = (angle - 90) * (pi / 180) + angleOffset / 2;
          }

          return AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.linear,
            left: rotatedX,
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

                // angle: angle ?? 0.0,
                child: MyCustomCard(
                  color: card["card"]["color"],
                  label: 'Card ${id.substring(0, 4)}',
                ),
              ),
            ),
          );
        })
        .toList()
        .reversed
        .toList();
  }

  void resetDeck() {
    setState(() {
      deckRaised = false;
      raisedCardId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: resetDeck,
      onHorizontalDragUpdate: (details) {
        setState(() {
          angleOffset += details.delta.dx * 0.002;
          angleOffset = angleOffset.clamp(-pi / 4, 0.0);
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
              height: 200,
              child: Stack(
                children: buildFanCardWidgets(),
              ),
            ),
          ),
        ],
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
    return Container(
      width: 85,
      height: 135,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}
