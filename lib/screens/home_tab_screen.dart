import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/fan_card_dial.dart';

class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Center(
              child: Text(
                '홈 페이지 내용',
                style: CustomTextStyles.h3,
              ),
            ),
          ],
        ),
        const FanCardDial()
      ],
    );
  }
}
