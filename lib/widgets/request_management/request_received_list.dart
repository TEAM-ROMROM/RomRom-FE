// 받은 요청 목록 sliver (필터링된 결과를 화면에서 전달받아 렌더링만 담당, 항목은 화면 근처만 생성)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
// Item.imageUrlList 확장 게터 사용을 위해 필요
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/common/staggered_list_item_entrance.dart';
import 'package:romrom_fe/widgets/request_list_item_card_widget.dart';

class RequestReceivedList extends StatelessWidget {
  final List<TradeRequestHistory> filteredRequests;
  final bool isLoading;
  // 마지막 조회 실패 여부 (빈 목록과 구분 > 다시 시도 표시)
  final bool hasLoadFailed;
  final VoidCallback onRetry;
  final void Function(TradeRequestHistory request) onCardTap;
  final void Function(TradeRequestHistory request) onMenuTap;

  const RequestReceivedList({
    super.key,
    required this.filteredRequests,
    required this.isLoading,
    required this.hasLoadFailed,
    required this.onRetry,
    required this.onCardTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    // 로딩 > 조회 실패 > 빈 목록 > 목록 순
    if (isLoading) {
      return const SliverToBoxAdapter(
        child: SizedBox(height: 150, child: Center(child: CommonLoadingIndicator())),
      );
    }

    if (hasLoadFailed) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: EmptyStateView.error(centerText: '받은 요청을 불러오지 못했어요', onRetry: onRetry),
        ),
      );
    }

    if (filteredRequests.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Center(
            child: Text('진행 중인 요청이 없습니다', style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White)),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      sliver: SliverList.builder(
        itemCount: filteredRequests.length,
        itemBuilder: (context, index) => StaggeredListItemEntrance(index: index, child: _buildRequestRow(index)),
      ),
    );
  }

  /// 받은 요청 1행: 카드 + 다음 행과 구분선 (마지막 행 제외)
  Widget _buildRequestRow(int index) {
    final request = filteredRequests[index];
    final giveItem = request.giveItem;

    return Column(
      children: [
        // 물품은 요청 보낸 물품, 시각·거래 방식·요청자는 요청 자체 값
        RequestListItemCardWidget(
          imageUrl: giveItem.imageUrlList.isNotEmpty ? giveItem.imageUrlList.first : '',
          title: giveItem.itemName ?? ' ',
          address: giveItem.address ?? '주소 미등록',
          requestedDate: request.requestedDate,
          requesterNickname: request.requester?.nickname,
          requesterProfileUrl: request.requester?.profileUrl,
          isNew: request.isNew ?? false,
          tradeOptions: request.requestedTradeOptions,
          tradeStatus: TradeStatus.fromServerName(request.tradeStatus) ?? TradeStatus.chatting,
          extraChargeAmount: request.requestedExtraChargeAmount,
          requestMessage: request.requestMessage,
          onTap: () => onCardTap(request),
          onMenuTap: () => onMenuTap(request),
        ),
        if (index < filteredRequests.length - 1) Divider(thickness: 1.5, color: AppColors.opacity10White, height: 32.h),
      ],
    );
  }
}
