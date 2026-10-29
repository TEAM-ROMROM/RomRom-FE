// 요청 관리 화면 상단의 내 물품 카드 캐러셀 (PageView)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/request_management_item_card.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/request_management_item_card_widget.dart';

class RequestItemCardsCarousel extends StatelessWidget {
  final List<RequestManagementItemCard> itemCards;
  final int currentCardIndex;
  final PageController cardController;
  final bool isLoading;
  final ValueChanged<int> onPageChanged;
  final void Function(RequestManagementItemCard card) onCardTap;

  const RequestItemCardsCarousel({
    super.key,
    required this.itemCards,
    required this.currentCardIndex,
    required this.cardController,
    required this.isLoading,
    required this.onPageChanged,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    if (itemCards.isEmpty) {
      return isLoading
          ? const SizedBox(height: 150, child: Center(child: CommonLoadingIndicator()))
          : Container(
              height: 326,
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Center(
                child: Text('등록된 물품이 없습니다', style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White)),
              ),
            );
    }

    return SizedBox(
      height: 334,
      child: PageView.builder(
        controller: cardController,
        onPageChanged: onPageChanged,
        itemCount: itemCards.length,
        itemBuilder: (context, index) {
          return AppPressable(
            scaleDown: AppPressable.scaleCard,
            enableRipple: false,
            onTap: () => onCardTap(itemCards[index]),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: RequestManagementItemCardWidget(
                card: itemCards[index],
                isActive: index == currentCardIndex,
                width: 219,
                height: 326,
              ),
            ),
          );
        },
      ),
    );
  }
}
