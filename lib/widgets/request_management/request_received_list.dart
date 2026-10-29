// 받은 요청 목록 (필터링된 결과를 화면에서 전달받아 렌더링만 담당)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/models/app_theme.dart';
// Item.imageUrlList 확장 게터 사용을 위해 필요
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/widgets/common/app_fade_slide_in.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/request_list_item_card_widget.dart';

class RequestReceivedList extends StatelessWidget {
  final List<TradeRequestHistory> filteredRequests;
  final bool isLoading;
  final void Function(TradeRequestHistory request) onCardTap;
  final void Function(TradeRequestHistory request) onMenuTap;

  const RequestReceivedList({
    super.key,
    required this.filteredRequests,
    required this.isLoading,
    required this.onCardTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    if (filteredRequests.isEmpty) {
      return isLoading
          ? const SizedBox(height: 150, child: Center(child: CommonLoadingIndicator()))
          : Container(
              height: 200,
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Center(
                child: Text('진행 중인 요청이 없습니다', style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White)),
              ),
            );
    }

    return isLoading
        ? const SizedBox(height: 150, child: Center(child: CommonLoadingIndicator()))
        : Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: List.generate(filteredRequests.length, (index) {
                final request = filteredRequests[index];
                final giveItem = request.giveItem;

                return AppFadeSlideIn(
                  delay: Duration(milliseconds: index * AppMotion.staggerDelayMs),
                  child: Column(
                    children: [
                      RequestListItemCardWidget(
                        imageUrl: giveItem.imageUrlList.isNotEmpty ? giveItem.imageUrlList.first : '',
                        title: giveItem.itemName ?? ' ',
                        address: giveItem.address ?? '주소 미등록',
                        createdDate: giveItem.createdDate ?? DateTime.now(),
                        isNew: request.isNew ?? false,
                        tradeOptions: ItemTradeOption.fromServerNamesSkippingUnknown(giveItem.itemTradeOptions),
                        tradeStatus: TradeStatus.fromServerName(request.tradeStatus) ?? TradeStatus.chatting,
                        onTap: () => onCardTap(request),
                        onMenuTap: () => onMenuTap(request),
                      ),
                      if (index < filteredRequests.length - 1)
                        Divider(thickness: 1.5, color: AppColors.opacity10White, height: 32.h),
                    ],
                  ),
                );
              }),
            ),
          );
  }
}
