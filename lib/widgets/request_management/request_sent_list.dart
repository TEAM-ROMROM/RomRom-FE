// 보낸 요청 목록 (정렬 칩 + 목록/빈상태/로딩) - 카드 탭·수정·취소 로직은 화면 콜백에 위임
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/enums/request_sort_type.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/models/app_theme.dart';
// Item.imageUrlList 확장 게터 사용을 위해 필요
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/widgets/common/app_fade_slide_in.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/request_management/request_sort_chip.dart';
import 'package:romrom_fe/widgets/sent_request_item_card.dart';

class RequestSentList extends StatelessWidget {
  final List<TradeRequestHistory> sentRequests;
  final bool isLoading;
  final RequestSortType currentSort;
  final ValueChanged<RequestSortType> onSortChanged;
  final void Function(TradeRequestHistory request) onCardTap;
  final void Function(TradeRequestHistory request) onEditTap;
  final void Function(TradeRequestHistory request) onCancelTap;

  const RequestSentList({
    super.key,
    required this.sentRequests,
    required this.isLoading,
    required this.currentSort,
    required this.onSortChanged,
    required this.onCardTap,
    required this.onEditTap,
    required this.onCancelTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 정렬 칩 행 (항상 표시)
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 16, 8),
          child: RequestSortChip(currentSort: currentSort, onChanged: onSortChanged),
        ),
        // 기존 목록/빈상태/로딩
        _buildListBody(),
      ],
    );
  }

  /// 보낸 요청 목록 본체
  Widget _buildListBody() {
    // 보낸 요청은 필터링 없이 모든 요청 표시
    if (sentRequests.isEmpty) {
      return isLoading
          ? const SizedBox(height: 500, child: Center(child: CommonLoadingIndicator()))
          : Container(
              height: 200,
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Center(
                child: Text('보낸 요청이 없습니다', style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White)),
              ),
            );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: List.generate(sentRequests.length, (index) {
          final request = sentRequests[index];
          final takeItem = request.takeItem;
          final giveItem = request.giveItem;

          return AppFadeSlideIn(
            delay: Duration(milliseconds: index * AppMotion.staggerDelayMs),
            child: Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: SentRequestItemCard(
                onTap: () => onCardTap(request),
                myItemImageUrl: giveItem.imageUrlList.isNotEmpty ? giveItem.imageUrlList.first : '',
                otherItemImageUrl: takeItem.imageUrlList.isNotEmpty ? takeItem.imageUrlList.first : '',
                otherUserProfileUrl: takeItem.member?.profileUrl ?? '',
                title: takeItem.itemName ?? ' ',
                location: takeItem.address ?? '주소 미등록',
                createdDate: takeItem.createdDate ?? DateTime.now(),
                tradeOptions: ItemTradeOption.fromServerNamesSkippingUnknown(takeItem.itemTradeOptions),
                tradeStatus: request.tradeStatus != null
                    ? TradeStatus.values.firstWhere(
                        (e) => e.serverName == request.tradeStatus,
                        orElse: () => TradeStatus.chatting,
                      )
                    : TradeStatus.chatting,
                onEditTap: () => onEditTap(request),
                onCancelTap: () => onCancelTap(request),
              ),
            ),
          );
        }),
      ),
    );
  }
}
