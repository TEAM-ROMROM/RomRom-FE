// 홈 카드 덱 카드 한 장 본문 (애니메이션 값 무관 > AnimatedBuilder child로 재사용)
import 'package:flutter/material.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/request_management_item_card.dart';
import 'package:romrom_fe/widgets/request_management_item_card_widget.dart';

class HomeTabCardBody extends StatelessWidget {
  final Item item;
  final double width;
  final double height;

  const HomeTabCardBody({super.key, required this.item, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return RequestManagementItemCardWidget(
      card: RequestManagementItemCard.fromItem(item, titleFallback: '물품'),
      width: width,
      height: height,
      isActive: true,
    );
  }
}
